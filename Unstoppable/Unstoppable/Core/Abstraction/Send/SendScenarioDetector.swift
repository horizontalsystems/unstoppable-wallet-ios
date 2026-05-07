import BigInt
import EvmKit
import Foundation
import MarketKit

/// Determines which UserOp shape to build for an AA send by checking whether
/// the AA account is deployed and whether the sendToken is already approved
/// to the paymaster. Always queries on-chain — fresh per call.
///
/// Dependencies are injected as closures so the detector can be unit-tested
/// without protocol-mocking.
class SendScenarioDetector {
    typealias FetchPaymasterAddress = (_ sendToken: EvmKit.Address, _ blockchainType: BlockchainType) async throws -> EvmKit.Address
    typealias FetchIsDeployed = (_ accountAddress: EvmKit.Address, _ blockchainType: BlockchainType) async throws -> Bool
    typealias FetchAllowance = (_ owner: EvmKit.Address, _ spender: EvmKit.Address, _ token: EvmKit.Address, _ blockchainType: BlockchainType) async throws -> BigUInt

    /// Any non-trivial allowance value is treated as MAX-approve. We always
    /// approve(MAX), so a value above 2^255 means the approve has landed on
    /// chain. Tighter thresholds (e.g. per-tx max cost) are not needed because
    /// the paymaster takes only the actual gas amount in postOp.
    private static let safetyThreshold = BigUInt(2).power(255)

    private let fetchPaymasterAddress: FetchPaymasterAddress
    private let fetchIsDeployed: FetchIsDeployed
    private let fetchAllowance: FetchAllowance

    init(
        fetchPaymasterAddress: @escaping FetchPaymasterAddress,
        fetchIsDeployed: @escaping FetchIsDeployed,
        fetchAllowance: @escaping FetchAllowance
    ) {
        self.fetchPaymasterAddress = fetchPaymasterAddress
        self.fetchIsDeployed = fetchIsDeployed
        self.fetchAllowance = fetchAllowance
    }

    func detect(
        accountAddress: EvmKit.Address,
        blockchainType: BlockchainType,
        sendToken: EvmKit.Address
    ) async throws -> SendScenario {
        let paymasterAddress = try await fetchPaymasterAddress(sendToken, blockchainType)

        let isDeployed = try await fetchIsDeployed(accountAddress, blockchainType)
        if !isDeployed {
            return .freshDeploy(paymaster: paymasterAddress)
        }

        let allowance = try await fetchAllowance(accountAddress, paymasterAddress, sendToken, blockchainType)
        return allowance >= Self.safetyThreshold
            ? .approvedSend(paymaster: paymasterAddress)
            : .approveAndSend(paymaster: paymasterAddress)
    }
}

extension SendScenarioDetector {
    enum SendScenario: Equatable {
        case freshDeploy(paymaster: EvmKit.Address)
        case approvedSend(paymaster: EvmKit.Address)
        case approveAndSend(paymaster: EvmKit.Address)

        var paymaster: EvmKit.Address {
            switch self {
            case let .freshDeploy(paymaster): return paymaster
            case let .approvedSend(paymaster): return paymaster
            case let .approveAndSend(paymaster): return paymaster
            }
        }

        var requiresApprove: Bool {
            switch self {
            case .freshDeploy, .approveAndSend: return true
            case .approvedSend: return false
            }
        }
    }
}
