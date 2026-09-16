import KindlingCore
import KindlingUI
import PhotosUI
import SwiftData
import SwiftUI

struct ImportFlowView: View {
    let items: [PhotosPickerItem]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.analyticsTracker) private var analytics
    @State private var coordinator = MemoryImportCoordinator()
    @State private var startedAt = Date()
    @State private var trackedCompletion = false

    var body: some View {
        NavigationStack {
            Group {
                if case .ready = coordinator.phase, let trip = coordinator.trip {
                    DraftReviewScreen(
                        trip: trip,
                        onSaved: { dismiss() },
                        onCancel: { coordinator.cancel(); dismiss() }
                    )
                } else {
                    progressContent
                }
            }
            .background(KindlingColor.background)
        }
        .task {
            startedAt = .now
            analytics.track(.importStarted(count: AnalyticsCountBucket(items.count)))
            coordinator.start(items: items, context: context)
        }
        .onChange(of: coordinator.phase) { _, phase in
            guard phase == .ready, !trackedCompletion else { return }
            trackedCompletion = true
            analytics.track(.importCompleted(
                duration: AnalyticsDurationBucket(seconds: Date().timeIntervalSince(startedAt)),
                count: AnalyticsCountBucket(items.count)
            ))
            analytics.track(.draftReviewOpened)
        }
    }

    private var progressContent: some View {
        VStack(spacing: Space.s3) {
            Spacer()
            EmberView(state: emberState, size: 120)
            Text(coordinator.phase.title)
                .font(.kindlingTitle)
                .foregroundStyle(KindlingColor.textPrimary)
                .multilineTextAlignment(.center)

            if case .failed(let message) = coordinator.phase {
                Text(message)
                    .font(.kindlingBody)
                    .foregroundStyle(KindlingColor.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Close") { dismiss() }
                    .buttonStyle(.kindlingPrimary)
            } else {
                ProgressView(value: coordinator.progress)
                    .tint(KindlingColor.accent)
                Text("\(coordinator.processedCount) of \(coordinator.selectedCount)")
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
                if coordinator.failedCount > 0 {
                    Text("\(coordinator.failedCount) item(s) could not be loaded. Kindling will continue with the rest.")
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Button("Cancel import") {
                    analytics.track(.importFailed(code: .cancelled))
                    coordinator.cancel()
                    dismiss()
                }
                .buttonStyle(.kindlingSecondary)
            }
            Spacer()
        }
        .padding(Space.s3)
    }

    private var emberState: EmberState {
        switch coordinator.phase {
        case .clustering, .resolvingPlaces: .arranging
        case .ready: .celebrating
        case .failed, .cancelled: .resting
        default: .gathering
        }
    }
}
