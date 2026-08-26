import Foundation

/// Deterministic, offline, zero-latency first-step suggestion.
///
/// A direct port of the rule set validated in Phase 0's browser prototype
/// (`prototype/step-engine.js`). The JS was a throwaway; the **rules** are the
/// asset, and its 20-case suite is carried over verbatim in the tests so this
/// engine is provably equivalent to the one users saw.
///
/// Rule order is significant — the first matching family wins, exactly as
/// `Array.prototype.find` did in the prototype. Do not reorder without re-running
/// the ported cases.
public struct TemplateStepEngine: StepSuggesting {
    public init() {}

    struct Rule: Sendable {
        let keywords: [String]
        let steps: [String]
    }

    static let rules: [Rule] = [
        Rule(keywords: ["reply", "respond", "email", "message", "text", "dm"], steps: [
            "Open the conversation and read the last message.",
            "Write a one-sentence reply without sending it yet.",
            "Type just the greeting and the person's name."
        ]),
        Rule(keywords: ["call", "phone", "ring"], steps: [
            "Find the number and put it on your screen.",
            "Write down the first sentence you want to say.",
            "Open the dialer and enter the number."
        ]),
        // Added after Phase 0: "talking to a friend" matched nothing and fell
        // through to the generic fallback, which read as a machine that hadn't
        // understood. Placed after `call` so "call the dentist" still routes there.
        Rule(keywords: [
            "talk", "talking", "conversation", "speak", "tell", "discuss",
            "confront", "apologise", "apologize", "catch up", "chat",
            "friend", "mum", "mom", "dad", "partner", "boss", "landlord"
        ], steps: [
            "Write down the first sentence you want to say.",
            "Decide how you'll reach them: call, message, or in person. Then pick one.",
            "Open their name on your phone and just look at it."
        ]),
        Rule(keywords: ["write", "essay", "report", "proposal", "article", "draft", "document"], steps: [
            "Open a blank document and write a rough title.",
            "Write one deliberately messy opening sentence.",
            "List three words the document needs to cover."
        ]),
        Rule(keywords: ["read", "study", "revise", "chapter", "paper"], steps: [
            "Open the material to the first unread page.",
            "Read only the first paragraph.",
            "Put the material in front of you and find your place."
        ]),
        Rule(keywords: ["clean", "tidy", "declutter", "room", "desk", "kitchen"], steps: [
            "Pick up one visible item and put it where it belongs.",
            "Clear one hand-sized patch of space.",
            "Bring an empty bag or basket into the room."
        ]),
        Rule(keywords: ["laundry", "wash clothes", "washing"], steps: [
            "Put one piece of clothing into the laundry basket.",
            "Bring the laundry basket next to the machine.",
            "Separate out just the first load."
        ]),
        Rule(keywords: ["dish", "dishes", "washing up"], steps: [
            "Put one dish beside the sink.",
            "Turn on the water and wash one cup.",
            "Gather the dishes from one surface."
        ]),
        Rule(keywords: ["pay", "bill", "invoice", "tax", "bank"], steps: [
            "Open the bill or payment page.",
            "Find the amount and due date. Nothing else yet.",
            "Put your payment details within reach."
        ]),
        Rule(keywords: ["shop", "shopping", "groceries", "buy", "errand", "parcel", "returns"], steps: [
            "Write down the first three things you need.",
            "Put your bag and keys by the door.",
            "Open the shop's page or app."
        ]),
        Rule(keywords: ["book", "appointment", "reserve", "schedule"], steps: [
            "Find the booking page or phone number.",
            "Open your calendar to a week that could work.",
            "Write down two times you could accept."
        ]),
        Rule(keywords: ["form", "application", "apply", "paperwork"], steps: [
            "Open the form and read only the first question.",
            "Put the first required document beside you.",
            "Fill in just your name."
        ]),
        Rule(keywords: ["pack", "packing", "suitcase", "bag"], steps: [
            "Put the empty bag where you can reach it.",
            "Place one essential item beside the bag.",
            "Write a list of just three essentials."
        ]),
        Rule(keywords: ["exercise", "workout", "run", "walk", "gym", "yoga"], steps: [
            "Put on the first piece of clothing you would exercise in.",
            "Put your shoes beside the door.",
            "Stand up and take one slow stretch."
        ])
    ]

    /// Used when no rule family matches. Never a dead end.
    static let fallbacks = [
        "Put the task in front of you: open the app, page, or object you'll need.",
        "Say the task out loud in your own words, then touch the first thing it needs.",
        "Set out one thing you will need. You can stop there."
    ]

    static let emptyTaskGuidance = "Type the thing you're avoiding, in any words that come to mind."

    /// Trims and collapses whitespace without otherwise changing the user's words.
    public static func normalize(_ task: String) -> String {
        task.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// Splits on anything that is not a letter or digit, which is the same place
    /// `\b` fell in the prototype's patterns. Every ported pattern was a plain
    /// alternation of literal words fenced by `\b` on both sides, so matching whole
    /// tokens is equivalent to running those regexes — and it stays `Sendable`,
    /// which a compiled `Regex` does not.
    static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    /// True when the keyword's own tokens appear as a contiguous run in `tokens`.
    /// Handles the multi-word entries ("wash clothes", "washing up") the same way
    /// the regex alternation did.
    static func matches(keyword: String, in tokens: [String]) -> Bool {
        let needle = tokenize(keyword)
        guard !needle.isEmpty, needle.count <= tokens.count else { return false }
        for start in 0...(tokens.count - needle.count) where Array(tokens[start ..< start + needle.count]) == needle {
            return true
        }
        return false
    }

    public func suggestFirstStep(for task: String, attempt: Int) -> String {
        let normalized = Self.normalize(task)
        guard !normalized.isEmpty else { return Self.emptyTaskGuidance }

        let tokens = Self.tokenize(normalized)
        // First matching family wins, exactly as `Array.prototype.find` did.
        let matched = Self.rules.first { rule in
            rule.keywords.contains { Self.matches(keyword: $0, in: tokens) }
        }
        let choices = matched?.steps ?? Self.fallbacks
        return choices[max(0, attempt) % choices.count]
    }
}
