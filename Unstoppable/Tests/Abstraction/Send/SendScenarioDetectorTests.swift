import BigInt
import EvmKit
import MarketKit
@testable import Unstoppable
@testable import WalletCore
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
}
