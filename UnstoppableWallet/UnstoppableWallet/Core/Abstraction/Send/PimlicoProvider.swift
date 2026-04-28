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
    private let sponsorshipPolicyId: String?
    private let url: URL
    private let headers: HTTPHeaders

    init(networkManager: NetworkManager, blockchainType: BlockchainType, entryPoint: EvmKit.Address, apiKey: String, sponsorshipPolicyId: String?) throws {
        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType) else {
            throw ProviderError.unsupportedChain
        }
        guard let url = URL(string: "https://api.pimlico.io/v2/\(chain.id)/rpc?apikey=\(apiKey)") else {
            throw ProviderError.invalidURL
        }

        self.networkManager = networkManager
        self.blockchainType = blockchainType
        self.entryPoint = entryPoint
        self.sponsorshipPolicyId = sponsorshipPolicyId
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
        let envelope: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_sendUserOperation",
            "params": [Self.serialize(userOp: userOp), entryPoint.eip55],
        ]

        let started = Date()
        print("[PimlicoProvider] → eth_sendUserOperation chain=\(blockchainType.uid)")

        let json: Any = try await networkManager.fetchJson(
            url: url,
            method: .post,
            parameters: envelope,
            encoding: JSONEncoding.default,
            headers: headers
        )

        let elapsedMs = Int(Date().timeIntervalSince(started) * 1000)

        guard let dict = json as? [String: Any] else {
            print("[PimlicoProvider] ← eth_sendUserOperation ERROR not a JSON object (\(elapsedMs)ms) raw=\(json)")
            throw ProviderError.malformedResponse(field: "envelope")
        }

        if let errorDict = dict["error"] as? [String: Any] {
            let code = errorDict["code"] as? Int ?? -32099
            let message = (errorDict["message"] as? String) ?? "unknown"
            print("[PimlicoProvider] ← eth_sendUserOperation ERROR code=\(code) message=\(message) (\(elapsedMs)ms) raw=\(dict)")
            throw ProviderError.rpc(code: code, message: message)
        }

        guard let resultStr = dict["result"] as? String else {
            print("[PimlicoProvider] ← eth_sendUserOperation ERROR no result/string (\(elapsedMs)ms) raw=\(dict)")
            throw ProviderError.rpc(code: -32099, message: "no result")
        }

        guard let data = resultStr.hs.hexData else {
            print("[PimlicoProvider] ← eth_sendUserOperation ERROR malformed hex result=\(resultStr) (\(elapsedMs)ms)")
            throw ProviderError.malformedResponse(field: "userOpHash hex")
        }

        print("[PimlicoProvider] ← eth_sendUserOperation OK (\(elapsedMs)ms)")
        return data
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

    func getTokenQuotes(tokens: [EvmKit.Address]) async throws -> [TokenQuote] {
        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType) else {
            throw ProviderError.unsupportedChain
        }

        let response: TokenQuotesResponse = try await rpcCall(
            method: "pimlico_getTokenQuotes",
            params: [
                ["tokens": tokens.map(\.eip55)],
                entryPoint.eip55,
                "0x" + String(chain.id, radix: 16),
            ]
        )
        return try response.quotes()
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
            if let sponsorshipPolicyId {
                context["sponsorshipPolicyId"] = sponsorshipPolicyId
            }
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

    func getPaymasterData(userOp: UserOperation, mode: PaymasterMode) async throws -> Data {
        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType) else {
            throw ProviderError.unsupportedChain
        }

        var context: [String: Any] = [:]
        switch mode {
        case .verifying:
            if let sponsorshipPolicyId {
                context["sponsorshipPolicyId"] = sponsorshipPolicyId
            }
        case let .erc20(token):
            context["token"] = token.eip55
        }

        let params: [Any] = [
            Self.serialize(userOp: userOp),
            entryPoint.eip55,
            "0x" + String(chain.id, radix: 16),
            context,
        ]

        let response: PaymasterStubResponse = try await rpcCall(method: "pm_getPaymasterData", params: params)
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

    struct TokenQuote: Equatable {
        let paymaster: EvmKit.Address
        let token: EvmKit.Address
        let postOpGas: BigUInt
        let exchangeRate: BigUInt
        let exchangeRateNativeToUsd: BigUInt
        let balanceSlot: String
        let allowanceSlot: String
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

        let started = Date()
        print("[PimlicoProvider] → \(method) chain=\(blockchainType.uid)")

        let response: RpcEnvelope<T> = try await networkManager.fetch(
            url: url,
            method: .post,
            parameters: envelope,
            encoding: JSONEncoding.default,
            headers: headers
        )

        let elapsedMs = Int(Date().timeIntervalSince(started) * 1000)

        if let error = response.error {
            print("[PimlicoProvider] ← \(method) ERROR code=\(error.code) message=\(error.message) (\(elapsedMs)ms)")
            throw ProviderError.rpc(code: error.code, message: error.message)
        }

        guard let result = response.result else {
            print("[PimlicoProvider] ← \(method) ERROR no result (\(elapsedMs)ms)")
            throw ProviderError.rpc(code: -32099, message: "no result")
        }

        print("[PimlicoProvider] ← \(method) OK (\(elapsedMs)ms)")
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

private struct TokenQuotesResponse: ImmutableMappable {
    let quotesPayload: [TokenQuotePayload]

    init(map: Map) throws {
        quotesPayload = try map.value("quotes")
    }

    func quotes() throws -> [PimlicoProvider.TokenQuote] {
        try quotesPayload.map { try $0.quote() }
    }

    struct TokenQuotePayload: ImmutableMappable {
        let paymaster: String
        let token: String
        let postOpGas: String
        let exchangeRate: String
        let exchangeRateNativeToUsd: String
        let balanceSlot: String
        let allowanceSlot: String

        init(map: Map) throws {
            paymaster = try map.value("paymaster")
            token = try map.value("token")
            postOpGas = try map.value("postOpGas")
            exchangeRate = try map.value("exchangeRate")
            exchangeRateNativeToUsd = try map.value("exchangeRateNativeToUsd")
            balanceSlot = try map.value("balanceSlot")
            allowanceSlot = try map.value("allowanceSlot")
        }

        func quote() throws -> PimlicoProvider.TokenQuote {
            guard let postOpGas = Self.bigUInt(from: postOpGas),
                  let exchangeRate = Self.bigUInt(from: exchangeRate),
                  let exchangeRateNativeToUsd = Self.bigUInt(from: exchangeRateNativeToUsd)
            else {
                throw PimlicoProvider.ProviderError.malformedResponse(field: "tokenQuote")
            }

            return try PimlicoProvider.TokenQuote(
                paymaster: EvmKit.Address(hex: paymaster),
                token: EvmKit.Address(hex: token),
                postOpGas: postOpGas,
                exchangeRate: exchangeRate,
                exchangeRateNativeToUsd: exchangeRateNativeToUsd,
                balanceSlot: balanceSlot,
                allowanceSlot: allowanceSlot
            )
        }

        private static func bigUInt(from hex: String) -> BigUInt? {
            let trimmed = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
            return BigUInt(trimmed, radix: 16)
        }
    }
}
