import Alamofire
import BigInt
import EvmKit
import Foundation
import HsExtensions
import HsToolKit
import MarketKit
import ObjectMapper

// JSON-RPC client for Pimlico bundler + ERC-4337 paymaster on a single chain.
// Endpoint pattern: https://api.pimlico.io/v2/{chainId}/rpc?apikey={KEY}.
// One instance per BlockchainType; constructed per-send call by AaSendHandler.instance(...).
//
// Sponsorship policy is enforced server-side on the API key (sponsor only when initCode != 0x).
// See memory: project_aa_v1_paymaster_policy.
class PimlicoProvider {
    private let networkManager: NetworkManager
    private let blockchainType: BlockchainType
    private let entryPoint: EvmKit.Address
    private let url: URL
    private let headers: HTTPHeaders

    init(networkManager: NetworkManager, blockchainType: BlockchainType, entryPoint: EvmKit.Address, apiKey: String) throws {
        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType) else {
            throw ProviderError.unsupportedChain
        }
        guard let url = URL(string: "https://api.pimlico.io/v2/\(chain.id)/rpc?apikey=\(apiKey)") else {
            throw ProviderError.invalidURL
        }

        self.networkManager = networkManager
        self.blockchainType = blockchainType
        self.entryPoint = entryPoint
        self.url = url
        headers = HTTPHeaders([HTTPHeader(name: "Content-Type", value: "application/json")])
    }
}

// MARK: - Public RPC methods

extension PimlicoProvider {
    var bundlerUrl: String {
        // Returned for archival in PendingUserOperationRecord.bundlerUrl.
        url.absoluteString
    }

    /// Submits a signed UserOp to the bundler. Returns the userOpHash echoed by the bundler.
    func sendUserOperation(userOp: UserOperation) async throws -> Data {
        let response: HexResponse = try await rpcCall(
            method: "eth_sendUserOperation",
            params: [Self.serialize(userOp: userOp), entryPoint.eip55]
        )
        return try response.dataValue()
    }

    /// Estimates the three gas dimensions for a UserOp (call, verification, preVerification).
    /// `userOp.signature` should be a dummy of correct length (Secp256r1VerificationFacet.dummySignature()).
    /// `userOp.paymasterAndData` should be the stub returned by getPaymasterStubData.
    func estimateUserOperationGas(userOp: UserOperation) async throws -> GasEstimate {
        let response: GasEstimateResponse = try await rpcCall(
            method: "eth_estimateUserOperationGas",
            params: [Self.serialize(userOp: userOp), entryPoint.eip55]
        )
        return try response.estimate()
    }

    /// Returns three priority tiers (slow / standard / fast) of EIP-1559 fees.
    /// v1 always picks `.standard`.
    func getUserOperationGasPrice() async throws -> GasPrices {
        let response: GasPricesResponse = try await rpcCall(
            method: "pimlico_getUserOperationGasPrice",
            params: []
        )
        return try response.prices()
    }

    /// Builds paymasterAndData for the given UserOp.
    /// Mode `.verifying` is sponsored (we pay), accepted by Pimlico only when initCode != 0x.
    /// Mode `.erc20` charges the user in the supplied ERC-20 token (via prior approval).
    func getPaymasterStubData(userOp: UserOperation, mode: PaymasterMode) async throws -> Data {
        // TODO: verify exact param shape against Pimlico docs at implementation time.
        // Current envelope follows ERC-7677 (pm_getPaymasterStubData) with Pimlico extensions:
        //   params: [userOp, entryPoint, chainIdHex, context]
        //   context: {} for verifying, {"token": "0x..."} for erc20.
        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType) else {
            throw ProviderError.unsupportedChain
        }

        var context: [String: Any] = [:]
        switch mode {
        case .verifying:
            break
        case let .erc20(token):
            context["token"] = token.eip55
        }

        let params: [Any] = [
            Self.serialize(userOp: userOp),
            entryPoint.eip55,
            "0x" + String(chain.id, radix: 16),
            context,
        ]

        let response: PaymasterStubResponse = try await rpcCall(method: "pm_getPaymasterStubData", params: params)
        return try response.paymasterAndDataValue()
    }
}

// MARK: - Public types

extension PimlicoProvider {
    enum PaymasterMode {
        case verifying
        case erc20(token: EvmKit.Address)

        var isSponsored: Bool {
            if case .verifying = self { return true }
            return false
        }
    }

    struct GasEstimate: Equatable {
        let callGasLimit: BigUInt
        let verificationGasLimit: BigUInt
        let preVerificationGas: BigUInt
    }

    struct GasPrices: Equatable {
        let slow: Tier
        let standard: Tier
        let fast: Tier

        struct Tier: Equatable {
            let maxFeePerGas: BigUInt
            let maxPriorityFeePerGas: BigUInt
        }
    }

    enum ProviderError: Error {
        case unsupportedChain
        case invalidURL
        case rpc(code: Int, message: String)
        case malformedResponse(field: String)
    }
}

// MARK: - JSON-RPC envelope

extension PimlicoProvider {
    private func rpcCall<T: ImmutableMappable>(method: String, params: [Any]) async throws -> T {
        let envelope: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params,
        ]

        let response: RpcEnvelope<T> = try await networkManager.fetch(
            url: url,
            method: .post,
            parameters: envelope,
            encoding: JSONEncoding.default,
            headers: headers
        )

        if let error = response.error {
            throw ProviderError.rpc(code: error.code, message: error.message)
        }

        guard let result = response.result else {
            throw ProviderError.rpc(code: -32099, message: "no result")
        }

        return result
    }

    /// Converts UserOperation to JSON-RPC dict form expected by Pimlico for v0.6 EntryPoint.
    /// All BigUInt fields → "0x…" hex; Data fields → "0x…" hex; Address → eip55.
    static func serialize(userOp: UserOperation) -> [String: String] {
        [
            "sender": userOp.sender.eip55,
            "nonce": hexString(userOp.nonce),
            "initCode": hexString(userOp.initCode),
            "callData": hexString(userOp.callData),
            "callGasLimit": hexString(userOp.callGasLimit),
            "verificationGasLimit": hexString(userOp.verificationGasLimit),
            "preVerificationGas": hexString(userOp.preVerificationGas),
            "maxFeePerGas": hexString(userOp.maxFeePerGas),
            "maxPriorityFeePerGas": hexString(userOp.maxPriorityFeePerGas),
            "paymasterAndData": hexString(userOp.paymasterAndData),
            "signature": hexString(userOp.signature),
        ]
    }

    private static func hexString(_ value: BigUInt) -> String {
        "0x" + (value == 0 ? "0" : String(value, radix: 16))
    }

    private static func hexString(_ data: Data) -> String {
        data.isEmpty ? "0x" : "0x" + data.hs.hex
    }
}

// MARK: - Response envelopes

private struct RpcEnvelope<T: ImmutableMappable>: ImmutableMappable {
    let result: T?
    let error: RpcErrorPayload?

    init(map: Map) throws {
        result = try? map.value("result")
        error = try? map.value("error")
    }
}

private struct RpcErrorPayload: ImmutableMappable {
    let code: Int
    let message: String

    init(map: Map) throws {
        code = try map.value("code")
        message = try map.value("message")
    }
}

private struct HexResponse: ImmutableMappable {
    let raw: String

    init(map: Map) throws {
        raw = try map.value("")
    }

    func dataValue() throws -> Data {
        guard let data = raw.hs.hexData else {
            throw PimlicoProvider.ProviderError.malformedResponse(field: "hex")
        }
        return data
    }
}

private struct GasEstimateResponse: ImmutableMappable {
    let callGasLimit: String
    let verificationGasLimit: String
    let preVerificationGas: String

    init(map: Map) throws {
        callGasLimit = try map.value("callGasLimit")
        verificationGasLimit = try map.value("verificationGasLimit")
        preVerificationGas = try map.value("preVerificationGas")
    }

    func estimate() throws -> PimlicoProvider.GasEstimate {
        guard let call = bigUInt(from: callGasLimit),
              let verify = bigUInt(from: verificationGasLimit),
              let preVer = bigUInt(from: preVerificationGas)
        else {
            throw PimlicoProvider.ProviderError.malformedResponse(field: "gasEstimate")
        }
        return PimlicoProvider.GasEstimate(
            callGasLimit: call,
            verificationGasLimit: verify,
            preVerificationGas: preVer
        )
    }

    private func bigUInt(from hex: String) -> BigUInt? {
        let trimmed = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        return BigUInt(trimmed, radix: 16)
    }
}

private struct GasPricesResponse: ImmutableMappable {
    let slow: TierPayload
    let standard: TierPayload
    let fast: TierPayload

    init(map: Map) throws {
        slow = try map.value("slow")
        standard = try map.value("standard")
        fast = try map.value("fast")
    }

    func prices() throws -> PimlicoProvider.GasPrices {
        try PimlicoProvider.GasPrices(
            slow: slow.tier(),
            standard: standard.tier(),
            fast: fast.tier()
        )
    }

    struct TierPayload: ImmutableMappable {
        let maxFeePerGas: String
        let maxPriorityFeePerGas: String

        init(map: Map) throws {
            maxFeePerGas = try map.value("maxFeePerGas")
            maxPriorityFeePerGas = try map.value("maxPriorityFeePerGas")
        }

        func tier() throws -> PimlicoProvider.GasPrices.Tier {
            guard let mfpg = bigUInt(from: maxFeePerGas),
                  let mpfpg = bigUInt(from: maxPriorityFeePerGas)
            else {
                throw PimlicoProvider.ProviderError.malformedResponse(field: "gasPrices")
            }
            return PimlicoProvider.GasPrices.Tier(maxFeePerGas: mfpg, maxPriorityFeePerGas: mpfpg)
        }

        private func bigUInt(from hex: String) -> BigUInt? {
            let trimmed = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
            return BigUInt(trimmed, radix: 16)
        }
    }
}

private struct PaymasterStubResponse: ImmutableMappable {
    let paymasterAndData: String

    init(map: Map) throws {
        paymasterAndData = try map.value("paymasterAndData")
    }

    func paymasterAndDataValue() throws -> Data {
        guard let data = paymasterAndData.hs.hexData else {
            throw PimlicoProvider.ProviderError.malformedResponse(field: "paymasterAndData")
        }
        return data
    }
}
