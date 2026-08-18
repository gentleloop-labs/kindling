import Foundation

/// String-backed so a new case never requires a schema migration — only an
/// app-level validation update.
public enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case active
    case steppedAway = "stepped_away"
    case done
    case discarded
}

public enum TaskSource: String, Codable, CaseIterable, Sendable {
    case typed
    case voice
}

public enum StepOrigin: String, Codable, CaseIterable, Sendable {
    case template
    case ai
    case edited
}

/// Three cases. There is no failure case and one must never be added — a session
/// that did not go well is `.distracted`, which is an outcome, not a failure.
public enum SessionOutcome: String, Codable, CaseIterable, Sendable {
    case keptGoing = "kept_going"
    case stoppedEnough = "stopped_enough"
    case distracted
}

public enum AiProvider: String, Codable, CaseIterable, Sendable {
    case onDevice = "on_device"
    case api
}
