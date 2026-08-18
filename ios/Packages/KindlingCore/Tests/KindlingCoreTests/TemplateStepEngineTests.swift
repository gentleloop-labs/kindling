import Testing
@testable import KindlingCore

/// The 20 cases below are carried over verbatim from
/// `prototype/tests/step-engine.test.mjs`. They are the specification: they are
/// what the Phase 0 prototype was validated against, so keeping them green is what
/// makes this Swift engine provably equivalent to the one real users saw.
///
/// When interviews produce real task wording, add cases — never quote an
/// interviewee's identifiable or sensitive task verbatim.
struct TemplateStepEngineTests {
    let engine = TemplateStepEngine()

    static let portedCases: [(task: String, expectedPrefix: String)] = [
        ("reply to the email", "Open the conversation"),
        ("Send Maya a message", "Open the conversation"),
        ("call the dentist", "Find the number"),
        ("write the quarterly report", "Open a blank document"),
        ("Draft my proposal", "Open a blank document"),
        ("read chapter four", "Open the material"),
        ("study for the exam", "Open the material"),
        ("clean my bedroom", "Pick up one visible item"),
        ("tidy desk", "Pick up one visible item"),
        ("do the laundry", "Put one piece of clothing"),
        ("wash the dishes", "Put one dish"),
        ("pay electricity bill", "Open the bill"),
        ("book a doctor appointment", "Find the booking page"),
        ("fill the application form", "Open the form"),
        ("pack for the trip", "Put the empty bag"),
        ("go for a run", "Put on the first piece"),
        ("start doing the thing", "Put the task in front of you"),
        ("organize project notes", "Put the task in front of you"),
        ("renew my passport", "Put the task in front of you"),
        ("decide what to cook", "Put the task in front of you")
    ]

    @Test("covers the Phase 0 task matrix, all 20 cases", arguments: portedCases)
    func portedMatrix(testCase: (task: String, expectedPrefix: String)) {
        let step = engine.suggestFirstStep(for: testCase.task)
        #expect(
            step.hasPrefix(testCase.expectedPrefix),
            "'\(testCase.task)' produced '\(step)'"
        )
    }

    @Test("the ported matrix is still the full 20 cases")
    func matrixSize() {
        #expect(Self.portedCases.count == 20)
    }

    @Test("normalizes whitespace without changing the user's words")
    func normalization() {
        #expect(TemplateStepEngine.normalize("  reply   to it \n today ") == "reply to it today")
    }

    @Test("empty input gets guidance, never a dead end")
    func emptyInput() {
        #expect(engine.suggestFirstStep(for: "   ").hasPrefix("Type the thing"))
        #expect(engine.suggestFirstStep(for: "").hasPrefix("Type the thing"))
    }

    @Test("regeneration is deterministic and cycles rather than randomising")
    func regeneration() {
        let first = engine.suggestFirstStep(for: "reply to the message", attempt: 0)
        let second = engine.suggestFirstStep(for: "reply to the message", attempt: 1)
        #expect(first != second)
        // Three steps per family, so attempt 3 comes back around to the first.
        #expect(engine.suggestFirstStep(for: "reply to the message", attempt: 3) == first)
        // Same input, same output, every time — no randomness anywhere.
        #expect(engine.suggestFirstStep(for: "reply to the message", attempt: 1) == second)
    }

    @Test("a negative attempt is clamped rather than trapping")
    func negativeAttempt() {
        let zero = engine.suggestFirstStep(for: "clean my desk", attempt: 0)
        #expect(engine.suggestFirstStep(for: "clean my desk", attempt: -5) == zero)
    }

    @Test("every rule family offers three steps, and there are enough families")
    func ruleShape() {
        #expect(TemplateStepEngine.rules.count >= 10)
        for rule in TemplateStepEngine.rules {
            #expect(rule.steps.count == 3)
            #expect(!rule.keywords.isEmpty)
        }
        #expect(TemplateStepEngine.fallbacks.count == 3)
    }

    @Test("keywords match whole words only, as the prototype's word boundaries did")
    func wordBoundaries() {
        // 'pay' must not fire on 'payment'; the fallback is the correct answer here.
        #expect(engine.suggestFirstStep(for: "sort out the paperwork").hasPrefix("Open the form"))
        #expect(!engine.suggestFirstStep(for: "repayment schedule is confusing").hasPrefix("Open the bill"))
    }

    @Test("multi-word keywords still match")
    func multiWordKeywords() {
        #expect(engine.suggestFirstStep(for: "wash clothes tonight").hasPrefix("Put one piece of clothing"))
        #expect(engine.suggestFirstStep(for: "do the washing up").hasPrefix("Put one piece of clothing"))
    }

    @Test("no suggestion is ever empty, whatever comes in")
    func neverEmpty() {
        for input in ["", "   ", "?????", "a", "REPLY TO THE EMAIL", "🙂"] {
            #expect(!engine.suggestFirstStep(for: input).isEmpty)
        }
    }
}

/// Cases added after Phase 0, from real use rather than the synthetic matrix.
/// These are separate from `portedCases` on purpose: that set is the validated
/// Phase 0 baseline and must not drift.
struct TemplateStepEngineCoverageTests {
    let engine = TemplateStepEngine()

    @Test("conversations get a conversation step, not the generic fallback", arguments: [
        "talking to a friend",
        "talk to my boss about the deadline",
        "tell mum about the move",
        "apologise to Sam",
        "have that conversation with my landlord",
        "catch up with an old friend"
    ])
    func conversationsAreRecognised(task: String) {
        let step = engine.suggestFirstStep(for: task)
        #expect(!step.hasPrefix("Put the task in front of you"), "'\(task)' fell through to the fallback")
    }

    @Test("errands get an errand step")
    func errands() {
        #expect(engine.suggestFirstStep(for: "do the grocery shopping").hasPrefix("Write down the first three"))
    }

    @Test("the Phase 0 baseline still routes exactly as validated", arguments: TemplateStepEngineTests.portedCases)
    func baselineUnchanged(testCase: (task: String, expectedPrefix: String)) {
        #expect(engine.suggestFirstStep(for: testCase.task).hasPrefix(testCase.expectedPrefix))
    }
}
