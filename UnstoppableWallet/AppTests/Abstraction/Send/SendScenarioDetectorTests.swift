import BigInt
import EvmKit
import MarketKit
@testable import Unstoppable
import XCTest

final class SendScenarioDetectorTests: XCTestCase {
    private let account = try! EvmKit.Address(hex: "0xed46df5b9032d564aa22d0487e0e2e7fdd889fd4")
    private let usdt = try! EvmKit.Address(hex: "0xdac17f958d2ee523a2206206994597c13d831ec7")
    private let paymaster = try! EvmKit.Address(hex: "0x4b742ad5ca91969e82aefb80072ae59121a3d72a")

    func testFreshDeploy_whenAccountNotDeployed() async throws {
        let detector = SendScenarioDetector(
            fetchPaymasterAddress: { _, _ in self.paymaster },
            fetchIsDeployed: { _, _ in false },
            fetchAllowance: { _, _, _, _ in
                XCTFail("allowance should not be queried for fresh deploy")
                return 0
            }
        )

        let scenario = try await detector.detect(accountAddress: account, blockchainType: .ethereum, sendToken: usdt)

        XCTAssertEqual(scenario, .freshDeploy(paymaster: paymaster))
    }

    func testApprovedSend_whenAllowanceIsMax() async throws {
        let detector = SendScenarioDetector(
            fetchPaymasterAddress: { _, _ in self.paymaster },
            fetchIsDeployed: { _, _ in true },
            fetchAllowance: { _, _, _, _ in BigUInt(2).power(256) - 1 }
        )

        let scenario = try await detector.detect(accountAddress: account, blockchainType: .ethereum, sendToken: usdt)

        XCTAssertEqual(scenario, .approvedSend(paymaster: paymaster))
    }

    func testApproveAndSend_whenAllowanceZero() async throws {
        let detector = SendScenarioDetector(
            fetchPaymasterAddress: { _, _ in self.paymaster },
            fetchIsDeployed: { _, _ in true },
            fetchAllowance: { _, _, _, _ in 0 }
        )

        let scenario = try await detector.detect(accountAddress: account, blockchainType: .ethereum, sendToken: usdt)

        XCTAssertEqual(scenario, .approveAndSend(paymaster: paymaster))
    }

    /// Two consecutive detect() calls with the same key must hit the in-memory
    /// cache on the second call. fetchAllowance is invoked once.
    func testCacheHit_skipsAllowanceQueryOnSecondCall() async throws {
        let allowanceCalls = Counter()
        let detector = SendScenarioDetector(
            fetchPaymasterAddress: { _, _ in self.paymaster },
            fetchIsDeployed: { _, _ in true },
            fetchAllowance: { _, _, _, _ in
                allowanceCalls.increment()
                return BigUInt(2).power(256) - 1
            }
        )

        _ = try await detector.detect(accountAddress: account, blockchainType: .ethereum, sendToken: usdt)
        _ = try await detector.detect(accountAddress: account, blockchainType: .ethereum, sendToken: usdt)

        XCTAssertEqual(allowanceCalls.value, 1)
    }

    /// Cache key includes the chain — same (account, token) on Mainnet vs BSC
    /// must miss the cache and re-query allowance.
    func testCacheMiss_whenChainDiffers() async throws {
        let allowanceCalls = Counter()
        let detector = SendScenarioDetector(
            fetchPaymasterAddress: { _, _ in self.paymaster },
            fetchIsDeployed: { _, _ in true },
            fetchAllowance: { _, _, _, _ in
                allowanceCalls.increment()
                return BigUInt(2).power(256) - 1
            }
        )

        _ = try await detector.detect(accountAddress: account, blockchainType: .ethereum, sendToken: usdt)
        _ = try await detector.detect(accountAddress: account, blockchainType: .binanceSmartChain, sendToken: usdt)

        XCTAssertEqual(allowanceCalls.value, 2)
    }

    /// A failed UserOp leaves on-chain allowance unchanged at 0. The detector
    /// stores the queried 0 in cache, but 0 < safetyThreshold, so the next
    /// detect call queries again and again returns .approveAndSend.
    func testCacheNotPromotedToApprovedWhenAllowanceBelowThreshold() async throws {
        let allowanceCalls = Counter()
        let detector = SendScenarioDetector(
            fetchPaymasterAddress: { _, _ in self.paymaster },
            fetchIsDeployed: { _, _ in true },
            fetchAllowance: { _, _, _, _ in
                allowanceCalls.increment()
                return 0
            }
        )

        let first = try await detector.detect(accountAddress: account, blockchainType: .ethereum, sendToken: usdt)
        let second = try await detector.detect(accountAddress: account, blockchainType: .ethereum, sendToken: usdt)

        XCTAssertEqual(first, .approveAndSend(paymaster: paymaster))
        XCTAssertEqual(second, .approveAndSend(paymaster: paymaster))
        XCTAssertEqual(allowanceCalls.value, 2, "below-threshold allowance must not satisfy cache; both detects re-query")
    }
}

private final class Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}
