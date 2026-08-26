import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

/// A small switcher, not a dashboard. It exposes only the decisions needed to
/// return to work or release a slot.
struct TaskShelfScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \AvoidedTask.updatedAt, order: .reverse) private var tasks: [AvoidedTask]

    let onResume: (UUID) -> Void
    let onStartNew: () -> Void
    let onRelease: (UUID) -> Void

    private var availableTasks: [AvoidedTask] {
        tasks.filter { ActiveTaskPolicy.countsTowardLimit($0.status) }
    }

    var body: some View {
        NavigationStack {
            List {
                if availableTasks.isEmpty {
                    ContentUnavailableView(
                        "Nothing parked",
                        systemImage: "checkmark.circle",
                        description: Text("Start with the thing you want a tiny nudge on.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(availableTasks) { task in
                        taskRow(task)
                    }
                }

                Section {
                    Button("Start something else") {
                        dismiss()
                        onStartNew()
                    }
                    .font(.kindlingButton)
                    .foregroundStyle(KindlingColor.accent)
                    .kindlingTapTarget()
                }
            }
            .scrollContentBackground(.hidden)
            .background(KindlingColor.background)
            .navigationTitle("Your tasks")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func taskRow(_ task: AvoidedTask) -> some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            Button {
                dismiss()
                onResume(task.id)
            } label: {
                VStack(alignment: .leading, spacing: Space.s1) {
                    Text(task.title)
                        .font(.kindlingBody)
                        .foregroundStyle(KindlingColor.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(task.status == .active ? "In progress" : "Stepped away")
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Resumes this task")

            HStack(spacing: Space.s2) {
                Button("Mark done") { finish(task, as: .done) }
                Button("Discard") { finish(task, as: .discarded) }
            }
            .font(.kindlingCaption)
            .foregroundStyle(KindlingColor.accent)
            .buttonStyle(.plain)
        }
        .padding(.vertical, Space.s1)
    }

    private func finish(_ task: AvoidedTask, as status: TaskStatus) {
        guard TaskStateMachine.canTransition(from: task.status, to: status) else { return }
        task.status = status
        task.updatedAt = .now
        try? context.save()
        onRelease(task.id)
    }
}
