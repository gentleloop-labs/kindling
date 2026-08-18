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

    /// Lets the shell hide its chrome for the duration of a session.
    @Binding var chromeVisible: Bool
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
                var aiEnabled = PreferencesStore(context: context)
                    .bool(PreferenceKey.aiStepsEnabled, default: false)
                #if DEBUG
                if ProcessInfo.processInfo.environment["KINDLING_FORCE_AI"] == "1" {
                    aiEnabled = true
                }
                #endif
                let created = RescueFlowModel(
                    context: context,
                    engine: StepEngineFactory.make(aiEnabled: aiEnabled)
                )
                #if DEBUG
                await created.applyDebugScreenOverride()
                #endif
                // Resume before the first frame the user sees, so a parked task
                // reopens with nothing to re-enter.
                if created.screen == .welcome {
                    created.restoreInterruptedWork()
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
                    model.screen = model.notificationAskAnswered ? .taskEntry : .notificationAsk
                })
            case .notificationAsk:
                NotificationAskScreen(
                    onAllow: {
                        model.notificationAskAnswered = true
                        Task {
                            let granted = await NotificationService.requestAuthorization()
                            PreferencesStore(context: context)
                                .set(PreferenceKey.notificationsOptIn, granted)
                            model.screen = .taskEntry
                        }
                    },
                    onDecline: {
                        // No guilt copy, and no second ask this session.
                        model.notificationAskAnswered = true
                        model.screen = .taskEntry
                    }
                )
            }
        }
        // Under Reduce Motion the screen simply changes, with no transition at all.
        .animation(KindlingMotion.standard(reduceMotion: reduceMotion), value: model.screen)
    }
}
