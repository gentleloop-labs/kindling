import KindlingCore
import SwiftData
import SwiftUI
import WidgetKit

/// Phase 1.3 smoke test — deliberately not product-facing.
///
/// It reads one row through the shared App Group container and renders its title.
/// That single read is what proves the whole stack: if SwiftData and the extension
/// sandbox are going to fight each other, it happens here, with nothing else in
/// flight. Phase 4 replaces this with the Live Activity.
struct SharedStoreProbeEntry: TimelineEntry {
    let date: Date
    let title: String
    let rowCount: Int
}

struct SharedStoreProbeProvider: TimelineProvider {
    func placeholder(in context: Context) -> SharedStoreProbeEntry {
        SharedStoreProbeEntry(date: .now, title: "Kindling", rowCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SharedStoreProbeEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SharedStoreProbeEntry>) -> Void) {
        completion(Timeline(entries: [readEntry()], policy: .never))
    }

    /// Opens the shared container from `KindlingCore`, so the extension cannot
    /// disagree with the app about where the store is.
    private func readEntry() -> SharedStoreProbeEntry {
        do {
            let container = try KindlingStore.makeModelContainer()
            let context = ModelContext(container)
            var descriptor = FetchDescriptor<AvoidedTask>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let all = try context.fetch(descriptor)
            descriptor.fetchLimit = 1
            return SharedStoreProbeEntry(
                date: .now,
                title: all.first?.title ?? "no rows yet",
                rowCount: all.count
            )
        } catch {
            return SharedStoreProbeEntry(date: .now, title: "store unavailable", rowCount: 0)
        }
    }
}

struct SharedStoreProbeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SharedStoreProbeWidget", provider: SharedStoreProbeProvider()) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text("Rows: \(entry.rowCount)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(entry.title)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .lineLimit(3)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Shared store probe")
        .description("Phase 1 smoke test: reads the app's store through the App Group.")
        .supportedFamilies([.systemSmall])
    }
}
