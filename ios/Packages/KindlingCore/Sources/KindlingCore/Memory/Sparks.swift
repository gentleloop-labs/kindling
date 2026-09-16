import Foundation

public enum SparkFamily: String, Codable, Sendable, CaseIterable {
    case sensory
    case emotional
    case social
    case surprise
    case recommendation
    case recallAnchor = "recall_anchor"
    case returnIntent = "return_intent"
}

public struct Spark: Sendable, Equatable, Identifiable {
    public let key: String
    public let version: Int
    public let family: SparkFamily
    public let text: String

    public var id: String { key }

    public init(key: String, version: Int = 1, family: SparkFamily, text: String) {
        self.key = key
        self.version = version
        self.family = family
        self.text = text
    }
}

public struct SparkSelector: Sendable {
    public static let launchLibrary: [Spark] = [
        Spark(key: "sensory.sound", family: .sensory, text: "What did this place sound like?"),
        Spark(key: "emotional.arrival", family: .emotional, text: "How did you feel arriving here?"),
        Spark(key: "social.better", family: .social, text: "Who made this moment better?"),
        Spark(key: "surprise.expected", family: .surprise, text: "What was different from what you expected?"),
        Spark(key: "recommendation.friend", family: .recommendation, text: "What would you tell a friend to try?"),
        Spark(key: "recall.before", family: .recallAnchor, text: "What happened just before this?"),
        Spark(key: "return.again", family: .returnIntent, text: "Would you come back?")
    ]

    public let library: [Spark]

    public init(library: [Spark] = Self.launchLibrary) {
        self.library = library
    }

    public func next(
        for momentID: UUID,
        excludingFamilies: Set<SparkFamily>,
        answeredKeys: Set<String>
    ) -> Spark? {
        let candidates = library.filter {
            !excludingFamilies.contains($0.family) && !answeredKeys.contains($0.key)
        }
        guard !candidates.isEmpty else { return nil }
        let checksum = momentID.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return candidates[checksum % candidates.count]
    }
}
