import Foundation
import Testing
@testable import KindlingCore

struct PlusNudgePolicyTests {
    private let now = Date(timeIntervalSince1970: 2_000_000)

    @Test("only forward-moving outcomes count as value moments")
    func valueMoments() {
        #expect(PlusNudgePolicy.countsAsValueMoment(.keptGoing))
        #expect(PlusNudgePolicy.countsAsValueMoment(.stoppedEnough))
        #expect(!PlusNudgePolicy.countsAsValueMoment(.distracted))
    }

    @Test("the invitation waits until Kindling has helped twice")
    func waitsForValue() {
        #expect(!PlusNudgePolicy.shouldShow(
            after: .stoppedEnough,
            hasPlus: false,
            valueMomentCount: 1,
            lastShownAt: nil,
            now: now
        ))
        #expect(PlusNudgePolicy.shouldShow(
            after: .stoppedEnough,
            hasPlus: false,
            valueMomentCount: 2,
            lastShownAt: nil,
            now: now
        ))
    }

    @Test("a distracted moment and Plus members are never prompted")
    func respectsContextAndEntitlement() {
        #expect(!PlusNudgePolicy.shouldShow(
            after: .distracted,
            hasPlus: false,
            valueMomentCount: 10,
            lastShownAt: nil,
            now: now
        ))
        #expect(!PlusNudgePolicy.shouldShow(
            after: .stoppedEnough,
            hasPlus: true,
            valueMomentCount: 10,
            lastShownAt: nil,
            now: now
        ))
    }

    @Test("dismissal buys fourteen quiet days")
    func cooldown() {
        #expect(!PlusNudgePolicy.shouldShow(
            after: .stoppedEnough,
            hasPlus: false,
            valueMomentCount: 3,
            lastShownAt: now.addingTimeInterval(-PlusNudgePolicy.cooldown + 1),
            now: now
        ))
        #expect(PlusNudgePolicy.shouldShow(
            after: .stoppedEnough,
            hasPlus: false,
            valueMomentCount: 3,
            lastShownAt: now.addingTimeInterval(-PlusNudgePolicy.cooldown),
            now: now
        ))
    }
}
