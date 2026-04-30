import BigInt
import EvmKit
import Foundation
import MarketKit

/// Determines which UserOp shape to build for an AA send by checking whether
/// the AA account is deployed and whether the sendToken is already approved
/// to the paymaster.
///
/// Allowance cache is in-memory, per app session, NOT persisted. On cache miss
/// the detector queries `eip20.allowance(owner, spender)` on chain. Cache is
/// updated only as a side-effect of detect() reading the live value — there is
/// no markApproved API. This keeps the strategy self-correcting: if a previous
/// approve UserOp reverted, on-chain allowance is still 0 and the next detect
/// correctly returns .approveAndSend.
///
/// Dependencies are injected as closures so the detector can be unit-tested
/// without protocol-mocking.
class SendScenarioDetector {
    typealias FetchPaymasterAddress = (_ sendToken: EvmKit.Address, _ blockchainType: BlockchainType) async throws -> EvmKit.Address
    typealias FetchIsDeployed = (_ accountAddress: EvmKit.Address, _ blockchainType: BlockchainType) async throws -> Bool
    typealias FetchAllowance = (_ owner: EvmKit.Address, _ spender: EvmKit.Address, _ token: EvmKit.Address, _ blockchainType: BlockchainType) async throws -> BigUInt

    /// Any non-trivial allowance value is treated as MAX-approve. We always
    /// approve(MAX), so a cached value above 2^255 means the approve has
    /// landed on chain. Tighter thresholds (e.g. per-tx max cost) are not
    /// needed because the paymaster takes only the actual gas amount in postOp.
    private static let safetyThreshold = BigUInt(2).power(255)

    private let fetchPaymasterAddress: FetchPaymasterAddress
    private let fetchIsDeployed: FetchIsDeployed
    private let fetchAllowance: FetchAllowance

    private var allowanceCache: [CacheKey: BigUInt] = [:]

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

        let key = CacheKey(
            account: accountAddress,
            blockchainType: blockchainType,
            token: sendToken,
            paymaster: paymasterAddress
        )

        if let cached = allowanceCache[key], cached >= Self.safetyThreshold {
            return .approvedSend(paymaster: paymasterAddress)
        }

        let allowance = try await fetchAllowance(accountAddress, paymasterAddress, sendToken, blockchainType)
        allowanceCache[key] = allowance

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

    fileprivate struct CacheKey: Hashable {
        let account: EvmKit.Address
        let blockchainType: BlockchainType
        let token: EvmKit.Address
        let paymaster: EvmKit.Address
    }
}
