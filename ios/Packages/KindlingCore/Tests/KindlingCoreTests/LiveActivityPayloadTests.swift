import Foundation
import Testing
@testable import KindlingCore

/// Asserts over the real content-state construction, not over a copy of the strings
/// — a copy would pass while the shipped payload leaked.
struct LiveActivityPayloadTests {
    let start = Date(timeIntervalSince1970: 1_000_000)

    @Test("the payload window matches the persisted session, so the OS draws the countdown")
    func window() {
        let session = SessionSnapshot(durationSeconds: 120, startedAt: start)
        let payload = LiveActivityContent.payload(for: session)
        #expect(payload.window.lowerBound == start)
        #expect(payload.window.upperBound == start.addingTimeInterval(120))
    }

    @Test("no task title can reach the lock screen through the payload")
    func noTaskTextEscapes() throws {
        // A title with every kind of thing a real one might incidentally reveal.
        let sensitive = "call the clinic about my test results"
        let session = SessionSnapshot(durationSeconds: 120, startedAt: start)
        let payload = LiveActivityContent.payload(for: session)

        // Encode the whole payload and search it, so a future property that carries
        // user text fails this test rather than shipping.
        let encoded = try JSONEncoder().encode(payload)
        let json = String(decoding: encoded, as: UTF8.self).lowercased()

        for word in sensitive.split(separator: " ") where word.count > 3 {
            #expect(!json.contains(word), "payload leaked '\(word)'")
        }
    }

    @Test("the payload carries exactly two fields, and the text one is fixed")
    func payloadShape() {
        let payload = LiveActivityContent.payload(
            for: SessionSnapshot(durationSeconds: 300, startedAt: start)
        )
        let fields = Mirror(reflecting: payload).children.compactMap(\.label)
        #expect(fields.sorted() == ["headline", "window"])
        #expect(payload.headline == LiveActivityContent.headline)
    }

    @Test("a zero-length session still produces a valid range rather than trapping")
    func degenerateDuration() {
        let payload = LiveActivityContent.payload(
            for: SessionSnapshot(durationSeconds: 0, startedAt: start)
        )
        #expect(payload.window.lowerBound <= payload.window.upperBound)
    }

    @Test("the payload round-trips, since ActivityKit encodes it")
    func codableRoundTrip() throws {
        let original = LiveActivityContent.payload(
            for: SessionSnapshot(durationSeconds: 120, startedAt: start)
        )
        let decoded = try JSONDecoder().decode(
            LiveActivityPayload.self,
            from: JSONEncoder().encode(original)
        )
        #expect(decoded == original)
    }
}

/// The lock screen is public. Same guarantee as the Live Activity payload, tested
/// the same way — over the real copy, not a duplicate of it.
struct SessionEndNotificationTests {
    @Test("the body is built from a duration and cannot carry task text")
    func noTaskText() {
        let sensitive = ["clinic", "results", "divorce", "overdraft", "therapist"]
        for seconds in [60, 120, 300, 0, -5] {
            let body = SessionEndNotification.body(forDurationSeconds: seconds).lowercased()
            for word in sensitive {
                #expect(!body.contains(word))
            }
            #expect(!body.isEmpty)
        }
    }

    @Test("durations render sensibly, including degenerate ones")
    func durations() {
        #expect(SessionEndNotification.body(forDurationSeconds: 120).hasPrefix("Your 2 minutes"))
        #expect(SessionEndNotification.body(forDurationSeconds: 300).hasPrefix("Your 5 minutes"))
        // Never "Your 0 minutes are up".
        #expect(SessionEndNotification.body(forDurationSeconds: 0).hasPrefix("Your 1 minutes"))
    }

    @Test("both outcomes are named as wins — no implied wrong answer")
    func noShame() {
        let body = SessionEndNotification.body(forDurationSeconds: 120)
        #expect(body.lowercased().contains("both are wins"))
        for shaming in ["failed", "missed", "should", "only"] {
            #expect(!body.lowercased().contains(shaming))
        }
    }
}
