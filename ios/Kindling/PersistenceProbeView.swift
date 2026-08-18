import KindlingCore
import SwiftData
import SwiftUI

/// Phase 1 probe, replaced by the real flow in Phase 3.
///
/// It exists to answer one question on a real device: does a row written here
/// survive a force-quit and a cold launch, and can the widget extension read the
/// same row through the App Group?
struct PersistenceProbeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \AvoidedTask.createdAt, order: .reverse) private var tasks: [AvoidedTask]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Write a row") { writeRow() }
                    Button("Delete all", role: .destructive) { deleteAll() }
                } footer: {
                    Text("Write a row, force-quit the app, then relaunch. The row must still be here, and the widget must show the same title.")
                }

                Section("Rows (\(tasks.count))") {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                            Text(task.createdAt.formatted(date: .omitted, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Store") {
                    LabeledContent("Path", value: storePath)
                        .font(.caption)
                }
            }
            .navigationTitle("Kindling")
            .task {
                #if DEBUG
                // Lets the cold-launch round-trip be checked from the command line
                // rather than by hand. Debug-only; never compiled into a release.
                if ProcessInfo.processInfo.environment["KINDLING_PROBE_WRITE"] == "1" {
                    writeRow()
                }
                #endif
            }
        }
    }

    private var storePath: String {
        (try? KindlingStore.storeURL().path(percentEncoded: false)) ?? "unavailable"
    }

    private func writeRow() {
        context.insert(AvoidedTask(title: "probe \(Date.now.formatted(date: .omitted, time: .standard))"))
        try? context.save()
    }

    private func deleteAll() {
        for task in tasks { context.delete(task) }
        try? context.save()
    }
}
