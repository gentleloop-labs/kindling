import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

/// Hosts the flow. Screens are swapped rather than pushed — there is no back
/// button to a screen the user has already answered, and no navigation chrome
/// competing with the one thing each screen asks for.
struct RescueFlowView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.analyticsTracker) private var analytics

    /// Lets the shell hide its chrome for the duration of a session.
    @Binding var chromeVisible: Bool
    @Binding var requestedTaskID: UUID?
    @Binding var releasedTaskID: UUID?
    @Binding var newTaskRequest: UUID?
    @Binding var aiConfigurationRevision: UUID
    @State private var model: RescueFlowModel?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                KindlingColor.background.ignoresSafeArea()
            }
        }
        .task {
            if model == nil {
                let preferences = PreferencesStore(context: context)
                var aiEnabled = preferences.bool(PreferenceKey.aiStepsEnabled, default: false)
                var hostedAIConsent = preferences.hostedAIConsent()
                #if DEBUG
                if ProcessInfo.processInfo.environment["KINDLING_FORCE_AI"] == "1" {
                    aiEnabled = true
                    hostedAIConsent = .allowed
                }
                #endif
                let created = RescueFlowModel(
                    context: context,
                    engine: StepEngineFactory.make(
                        aiEnabled: aiEnabled,
                        hostedAIConsent: hostedAIConsent
                    ),
                    analytics: analytics
                )
                #if DEBUG
                await created.applyDebugScreenOverride()
                #endif
                // Resume before the first frame the user sees, so a parked task
                // reopens with nothing to re-enter.
                if created.screen == .welcome {
                    created.restoreInterruptedWork()
                }
                if created.screen == .welcome {
                    analytics.track(.onboardingStarted)
                }
                if created.screen == .taskEntry {
                    created.engine.prewarm()
                }
                model = created
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model?.handleForeground() }
        }
        .onChange(of: model?.screen) { _, screen in
            // Nothing but the step, the timer, and Stop during a session.
            chromeVisible = screen != .session
        }
        .onChange(of: requestedTaskID) { _, id in
            guard let id else { return }
            model?.resumeTask(id: id)
            requestedTaskID = nil
        }
        .onChange(of: releasedTaskID) { _, id in
            guard let id else { return }
            model?.handleReleasedTask(id: id)
            releasedTaskID = nil
        }
        .onChange(of: newTaskRequest) { _, request in
            guard request != nil else { return }
            model?.beginNewTask()
            newTaskRequest = nil
        }
        .onChange(of: aiConfigurationRevision) { _, _ in
            guard let model else { return }
            let preferences = PreferencesStore(context: context)
            model.engine = StepEngineFactory.make(
                aiEnabled: preferences.bool(PreferenceKey.aiStepsEnabled, default: false),
                hostedAIConsent: preferences.hostedAIConsent()
            )
        }
    }

    @ViewBuilder
    private func content(_ model: RescueFlowModel) -> some View {
        ZStack {
            switch model.screen {
            case .welcome:
                WelcomeScreen(onContinue: model.beginRescue)
            case .taskEntry:
                TaskEntryScreen(
                    title: Binding(get: { model.draftTitle }, set: { model.draftTitle = $0 }),
                    canContinue: model.canContinueFromTaskEntry,
                    onUseSample: model.useSampleTask,
                    onContinue: { Task { await model.showFirstStep() } }
                )
            case .firstStep:
                FirstStepScreen(
                    echoedTask: model.echoedTask,
                    step: model.suggestedStep,
                    durationSeconds: model.durationSeconds,
                    isGenerating: model.isGeneratingStep,
                    onStart: model.startSession,
                    onRegenerate: { Task { await model.regenerateStep() } }
                )
            case .session:
                if let snapshot = model.sessionSnapshot {
                    SessionScreen(
                        snapshot: snapshot,
                        step: model.suggestedStep,
                        onStop: model.stopSession,
                        onElapsed: model.sessionElapsed
                    )
                }
            case .outcome:
                OutcomeScreen(onChoose: model.record(outcome:))
            case .success:
                SuccessScreen(onContinue: {
                    if model.notificationAskAnswered {
                        model.beginNewTask()
                    } else {
                        model.screen = .notificationAsk
                    }
                })
            case .notificationAsk:
                NotificationAskScreen(
                    onAllow: {
                        model.notificationAskAnswered = true
                        Task {
                            let granted = await NotificationService.requestAuthorization()
                            analytics.track(.notificationPermission(
                                granted ? .allowed : .declined
                            ))
                            PreferencesStore(context: context)
                                .set(PreferenceKey.notificationsOptIn, granted)
                            model.beginNewTask()
                        }
                    },
                    onDecline: {
                        analytics.track(.notificationPermission(.declined))
                        // No guilt copy, and no second ask this session.
                        model.notificationAskAnswered = true
                        model.beginNewTask()
                    }
                )
            }
        }
        // Under Reduce Motion the screen simply changes, with no transition at all.
        .animation(KindlingMotion.standard(reduceMotion: reduceMotion), value: model.screen)
    }
}
