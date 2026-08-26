import Foundation
import Testing
@testable import KindlingCore

/// The interrupted-session paths. These are the tests that matter most — everything
/// here is about time passing while the app was not running.
struct SessionRuntimeTests {
    let start = Date(timeIntervalSince1970: 1_000_000)
    func session(_ duration: Int = 120, endedAt: Date? = nil) -> SessionSnapshot {
        SessionSnapshot(durationSeconds: duration, startedAt: start, endedAt: endedAt)
    }

    @Test("a fresh session reports its full duration")
    func fresh() {
        let phase = SessionRuntime.phase(of: session(), clock: .fixed(start))
        #expect(phase == .running(remaining: 120))
    }

    @Test("remaining time is derived from wall-clock, not counted down in memory")
    func derivesFromWallClock() {
        let clock = SessionClock.fixed(start.addingTimeInterval(45))
        #expect(SessionRuntime.remaining(of: session(), clock: clock) == 75)
    }

    @Test("backgrounded for a while, then reopened mid-session")
    func backgroundedAndReopened() {
        let clock = SessionClock.fixed(start.addingTimeInterval(90))
        #expect(SessionRuntime.phase(of: session(), clock: clock) == .running(remaining: 30))
    }

    @Test("force-quit and relaunched after the timer would have ended")
    func forceQuitPastTheEnd() {
        let clock = SessionClock.fixed(start.addingTimeInterval(600))
        #expect(SessionRuntime.phase(of: session(), clock: clock) == .elapsed)
        #expect(SessionRuntime.endedWhileAway(session(), clock: clock))
    }

    @Test("relaunched exactly at the scheduled end counts as elapsed")
    func exactlyAtEnd() {
        let clock = SessionClock.fixed(start.addingTimeInterval(120))
        #expect(SessionRuntime.phase(of: session(), clock: clock) == .elapsed)
    }

    @Test("device rebooted mid-session — the session is still correct on return")
    func rebootMidSession() {
        // A reboot is indistinguishable from any other gap, which is the point of
        // deriving from a persisted start rather than holding a timer in memory.
        let clock = SessionClock.fixed(start.addingTimeInterval(119))
        #expect(SessionRuntime.remaining(of: session(), clock: clock) == 1)
    }

    @Test("clock moved backwards never hands out more time than the session was set for")
    func clockMovedBackwards() {
        let clock = SessionClock.fixed(start.addingTimeInterval(-10_000))
        #expect(SessionRuntime.remaining(of: session(), clock: clock) == 120)
        #expect(SessionRuntime.progress(of: session(), clock: clock) == 0)
    }

    @Test("clock moved far forward ends the session rather than going negative")
    func clockMovedForward() {
        let clock = SessionClock.fixed(start.addingTimeInterval(10_000_000))
        #expect(SessionRuntime.remaining(of: session(), clock: clock) == 0)
        #expect(SessionRuntime.progress(of: session(), clock: clock) == 1)
    }

    @Test("a session stopped early is distinguishable from one that ran out")
    func stoppedEarly() {
        let stopped = session(endedAt: start.addingTimeInterval(30))
        #expect(SessionRuntime.phase(of: stopped, clock: .fixed(start.addingTimeInterval(30))) == .stoppedEarly)
        #expect(!SessionRuntime.endedWhileAway(stopped, clock: .fixed(start.addingTimeInterval(600))))

        let ranOut = session(endedAt: start.addingTimeInterval(120))
        #expect(SessionRuntime.phase(of: ranOut, clock: .fixed(start.addingTimeInterval(120))) == .elapsed)
    }

    @Test("progress climbs from empty to full across the session", arguments: [
        (0.0, 0.0), (30.0, 0.25), (60.0, 0.5), (120.0, 1.0), (121.0, 1.0)
    ])
    func progressCurve(elapsed: Double, expected: Double) {
        let clock = SessionClock.fixed(start.addingTimeInterval(elapsed))
        #expect(abs(SessionRuntime.progress(of: session(), clock: clock) - expected) < 0.0001)
    }

    @Test("the 5-minute option behaves the same as the 2-minute one")
    func fiveMinuteSession() {
        let clock = SessionClock.fixed(start.addingTimeInterval(200))
        #expect(SessionRuntime.remaining(of: session(300), clock: clock) == 100)
    }
}

struct TaskStateMachineTests {
    @Test("a live task can be parked, finished, or discarded")
    func fromActive() {
        #expect(TaskStateMachine.canTransition(from: .active, to: .steppedAway))
        #expect(TaskStateMachine.canTransition(from: .active, to: .done))
        #expect(TaskStateMachine.canTransition(from: .active, to: .discarded))
    }

    @Test("a parked task can always be picked back up")
    func resumeIsAlwaysAllowed() {
        #expect(TaskStateMachine.canTransition(from: .steppedAway, to: .active))
    }

    @Test("finishing is reopenable; discarding is the one end point")
    func terminalStates() {
        #expect(TaskStateMachine.canTransition(from: .done, to: .active))
        for status in TaskStatus.allCases {
            #expect(!TaskStateMachine.canTransition(from: .discarded, to: status))
        }
    }

    @Test("no status transitions to itself")
    func noSelfTransitions() {
        for status in TaskStatus.allCases {
            #expect(!TaskStateMachine.canTransition(from: status, to: status))
        }
    }

    @Test("all three outcomes land somewhere legitimate, and none marks the task done")
    func outcomeLandings() {
        #expect(TaskStateMachine.status(after: .keptGoing, from: .active) == .active)
        #expect(TaskStateMachine.status(after: .stoppedEnough, from: .active) == .steppedAway)
        #expect(TaskStateMachine.status(after: .distracted, from: .active) == .steppedAway)

        // Only the user marks something done — no outcome does it for them.
        for outcome in SessionOutcome.allCases {
            #expect(TaskStateMachine.status(after: outcome, from: .active) != .done)
            #expect(TaskStateMachine.status(after: outcome, from: .active) != .discarded)
        }
    }
}

struct ActiveTaskPolicyTests {
    @Test("the free tier holds exactly one active task")
    func freeTierCeiling() {
        #expect(ActiveTaskPolicy.canStartAnotherTask(currentActiveCount: 0, hasMultiTaskEntitlement: false))
        #expect(!ActiveTaskPolicy.canStartAnotherTask(currentActiveCount: 1, hasMultiTaskEntitlement: false))
    }

    @Test("the entitlement lifts the ceiling")
    func paidTier() {
        #expect(ActiveTaskPolicy.canStartAnotherTask(currentActiveCount: 5, hasMultiTaskEntitlement: true))
    }

    @Test("active and stepped-away tasks both occupy the free slot")
    func countedStatuses() {
        #expect(ActiveTaskPolicy.countsTowardLimit(.active))
        #expect(ActiveTaskPolicy.countsTowardLimit(.steppedAway))
        #expect(!ActiveTaskPolicy.countsTowardLimit(.done))
        #expect(!ActiveTaskPolicy.countsTowardLimit(.discarded))
        #expect(ActiveTaskPolicy.currentActiveCount(in: TaskStatus.allCases) == 2)
    }

    @Test("finishing or discarding releases the free slot")
    func terminalStatusesReleaseSlot() {
        for status in [TaskStatus.done, .discarded] {
            let count = ActiveTaskPolicy.currentActiveCount(in: [status])
            #expect(ActiveTaskPolicy.canStartAnotherTask(
                currentActiveCount: count,
                hasMultiTaskEntitlement: false
            ))
        }
    }
}

struct ProductIDTests {
    @Test("all three §15 products grant the multi-task entitlement")
    func everyProductGrants() {
        for id in ProductID.all {
            #expect(ProductID.entitlement(for: id) == .multiTask)
        }
        #expect(ProductID.all.count == 3)
    }

    @Test("an unrecognised product grants nothing")
    func unknownProductGrantsNothing() {
        // StoreKit can hand back a transaction for a product this build no longer
        // knows about. "I don't recognise this" must read as *grants nothing*.
        #expect(ProductID.entitlement(for: "dev.aftaab.kindling.something.else") == nil)
        #expect(ProductID.entitlement(for: "") == nil)
    }

    @Test("product identifiers are namespaced under the bundle ID and are distinct")
    func identifiersAreWellFormed() {
        // A typo here is invisible at build time and surfaces only as "no products
        // found" on a real device, long after the mistake was made.
        for id in ProductID.all {
            #expect(id.hasPrefix("dev.aftaab.kindling."))
        }
        #expect(Set([ProductID.monthly, ProductID.annual, ProductID.lifetime]).count == 3)
    }
}
