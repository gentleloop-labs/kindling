import SwiftData

/// Permanently removes a task and all of the task-owned data covered by the
/// schema's cascade rules.
@MainActor
public enum TaskDataDeletion {
    public static func delete(_ task: AvoidedTask, from context: ModelContext) throws {
        context.delete(task)
        try context.save()
    }
}
