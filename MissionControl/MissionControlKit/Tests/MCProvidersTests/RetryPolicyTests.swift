import Testing
@testable import MCProviders

@Suite struct RetryPolicyTests {
    @Test func stopsImmediatelyOnSuccess() async {
        let policy = RetryPolicy(maxAttemptsPerCycle: 3, baseDelay: 0.01, maxDelay: 0.02)
        var callCount = 0
        let result = await policy.run(clock: { _ in }) { _ in
            callCount += 1
            return (.success, nil)
        }
        guard case .success = result else { Issue.record("expected success"); return }
        #expect(callCount == 1)
    }

    @Test func stopsImmediatelyOnTerminalFailure() async {
        let policy = RetryPolicy(maxAttemptsPerCycle: 3, baseDelay: 0.01, maxDelay: 0.02)
        var callCount = 0
        let result = await policy.run(clock: { _ in }) { _ in
            callCount += 1
            return (.terminal(reason: "401"), nil)
        }
        guard case .terminal = result else { Issue.record("expected terminal"); return }
        #expect(callCount == 1)
    }

    @Test func retriesTransientFailuresUpToMaxAttempts() async {
        let policy = RetryPolicy(maxAttemptsPerCycle: 3, baseDelay: 0.01, maxDelay: 0.02)
        var callCount = 0
        let result = await policy.run(clock: { _ in }) { _ in
            callCount += 1
            return (.transient(reason: "network error"), nil)
        }
        guard case .transient = result else { Issue.record("expected transient"); return }
        #expect(callCount == 3)
    }

    @Test func succeedsAfterInitialTransientFailure() async {
        let policy = RetryPolicy(maxAttemptsPerCycle: 3, baseDelay: 0.01, maxDelay: 0.02)
        var callCount = 0
        let result = await policy.run(clock: { _ in }) { attempt in
            callCount += 1
            if attempt == 0 {
                return (.transient(reason: "429"), nil)
            }
            return (.success, nil)
        }
        guard case .success = result else { Issue.record("expected success"); return }
        #expect(callCount == 2)
    }
}
