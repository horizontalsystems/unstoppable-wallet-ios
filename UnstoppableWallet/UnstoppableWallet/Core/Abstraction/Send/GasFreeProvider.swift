import Alamofire
import BigInt
import CryptoKit
import Foundation
import HsToolKit
import TronKit

// HTTP client for the GasFree.io REST API at `open.gasfree.io/tron`.
// Spec: docs/aa-reports/tron-gasfree-api-spec.md
//
// Auth: HMAC-SHA256(secret, METHOD + FULL_PATH + TIMESTAMP_STR), base64. Headers:
//   Timestamp:     <unix-seconds>
//   Authorization: ApiKey <api-key>:<signature>
//
// Response envelope: { code, reason, message, data }. `code == 200` is success.
class GasFreeProvider {
    private static let mainnetBaseURL = "https://open.gasfree.io/tron"
    private static let mainnetSignaturePathPrefix = "/tron"

    private let networkManager: NetworkManager
    private let apiKey: String
    private let apiSecret: String

    init(networkManager: NetworkManager, apiKey: String, apiSecret: String) throws {
        guard !apiKey.isEmpty, !apiSecret.isEmpty else {
            throw ProviderError.missingCredentials
        }
        self.networkManager = networkManager
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
}

// MARK: - Public methods

extension GasFreeProvider {
    func tokens() async throws -> [TokenInfo] {
        let payload = try await get(apiPath: "/api/v1/config/token/all")
        guard let data = payload["tokens"] as? [[String: Any]] else {
            throw ProviderError.malformedResponse(field: "tokens")
        }
        return try data.map { try TokenInfo(json: $0) }
    }

    func providers() async throws -> [ProviderInfo] {
        let payload = try await get(apiPath: "/api/v1/config/provider/all")
        guard let data = payload["providers"] as? [[String: Any]] else {
            throw ProviderError.malformedResponse(field: "providers")
        }
        return try data.map { try ProviderInfo(json: $0) }
    }

    func accountInfo(controllerAddress: TronKit.Address) async throws -> AccountInfo {
        let payload = try await get(apiPath: "/api/v1/address/\(controllerAddress.base58)")
        return try AccountInfo(json: payload)
    }

    func submitTransfer(_ request: SubmitTransferRequest) async throws -> TransferStatus {
        let body = request.jsonBody
        let payload = try await post(apiPath: "/api/v1/gasfree/submit", body: body)
        return try TransferStatus(json: payload)
    }

    func transferStatus(traceId: String) async throws -> TransferStatus {
        let payload = try await get(apiPath: "/api/v1/gasfree/\(traceId)")
        return try TransferStatus(json: payload)
    }
}

// MARK: - Signature (testable pure helper)

extension GasFreeProvider {
    static func computeSignature(method: String, fullPath: String, timestamp: Int, apiSecret: String) -> String {
        let message = "\(method)\(fullPath)\(timestamp)"
        let key = SymmetricKey(data: Data(apiSecret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        return Data(mac).base64EncodedString()
    }
}

// MARK: - HTTP plumbing

private extension GasFreeProvider {
    func get(apiPath: String) async throws -> [String: Any] {
        try await rpcCall(method: "GET", apiPath: apiPath, body: nil)
    }

    func post(apiPath: String, body: [String: Any]) async throws -> [String: Any] {
        try await rpcCall(method: "POST", apiPath: apiPath, body: body)
    }

    func rpcCall(method: String, apiPath: String, body: [String: Any]?) async throws -> [String: Any] {
        guard let url = URL(string: Self.mainnetBaseURL + apiPath) else {
            throw ProviderError.invalidURL
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let fullPath = Self.mainnetSignaturePathPrefix + apiPath
        let signature = Self.computeSignature(method: method, fullPath: fullPath, timestamp: timestamp, apiSecret: apiSecret)

        let headers = HTTPHeaders([
            HTTPHeader(name: "Content-Type", value: "application/json"),
            HTTPHeader(name: "Timestamp", value: "\(timestamp)"),
            HTTPHeader(name: "Authorization", value: "ApiKey \(apiKey):\(signature)"),
        ])

        let started = Date()
        print("[GasFreeProvider] → \(method) \(apiPath)")

        let json: Any
        do {
            json = try await networkManager.fetchJson(
                url: url,
                method: method == "POST" ? .post : .get,
                parameters: body ?? [:],
                encoding: JSONEncoding.default,
                headers: headers
            )
        } catch {
            print("[GasFreeProvider] ← \(method) \(apiPath) network error: \(error)")
            throw error
        }

        let elapsedMs = Int(Date().timeIntervalSince(started) * 1000)

        guard let dict = json as? [String: Any] else {
            print("[GasFreeProvider] ← \(method) \(apiPath) ERROR not a JSON object (\(elapsedMs)ms)")
            throw ProviderError.malformedResponse(field: "envelope")
        }

        let code = dict["code"] as? Int ?? -1
        if code != 200 {
            let reason = dict["reason"] as? String ?? "unknown"
            let message = dict["message"] as? String ?? ""
            print("[GasFreeProvider] ← \(method) \(apiPath) ERROR code=\(code) reason=\(reason) message=\(message) (\(elapsedMs)ms)")
            throw ProviderError.api(code: code, reason: reason, message: message)
        }

        guard let data = dict["data"] as? [String: Any] else {
            print("[GasFreeProvider] ← \(method) \(apiPath) ERROR missing data (\(elapsedMs)ms)")
            throw ProviderError.malformedResponse(field: "data")
        }

        print("[GasFreeProvider] ← \(method) \(apiPath) OK (\(elapsedMs)ms)")
        return data
    }
}

// MARK: - Public types

extension GasFreeProvider {
    struct TokenInfo: Equatable {
        let tokenAddress: TronKit.Address
        let symbol: String
        let decimal: Int
        let activateFee: BigUInt
        let transferFee: BigUInt
        let supported: Bool

        init(json: [String: Any]) throws {
            guard let addressStr = json["tokenAddress"] as? String,
                  let tokenAddress = try? TronKit.Address(address: addressStr)
            else {
                throw ProviderError.malformedResponse(field: "tokenAddress")
            }
            guard let symbol = json["symbol"] as? String else {
                throw ProviderError.malformedResponse(field: "symbol")
            }
            guard let decimal = json["decimal"] as? Int else {
                throw ProviderError.malformedResponse(field: "decimal")
            }

            self.tokenAddress = tokenAddress
            self.symbol = symbol
            self.decimal = decimal
            activateFee = parseBigUInt(json["activateFee"]) ?? 0
            transferFee = parseBigUInt(json["transferFee"]) ?? 0
            supported = json["supported"] as? Bool ?? false
        }
    }

    struct ProviderInfo: Equatable {
        let address: TronKit.Address
        let name: String
        let maxPendingTransfer: Int
        let minDeadlineDuration: Int
        let maxDeadlineDuration: Int
        let defaultDeadlineDuration: Int

        init(json: [String: Any]) throws {
            guard let addressStr = json["address"] as? String,
                  let address = try? TronKit.Address(address: addressStr)
            else {
                throw ProviderError.malformedResponse(field: "address")
            }

            self.address = address
            name = json["name"] as? String ?? ""

            let config = json["config"] as? [String: Any] ?? [:]
            maxPendingTransfer = config["maxPendingTransfer"] as? Int ?? 0
            minDeadlineDuration = config["minDeadlineDuration"] as? Int ?? 0
            maxDeadlineDuration = config["maxDeadlineDuration"] as? Int ?? 0
            defaultDeadlineDuration = config["defaultDeadlineDuration"] as? Int ?? 0
        }
    }

    struct AccountInfo: Equatable {
        let accountAddress: TronKit.Address
        let gasFreeAddress: TronKit.Address
        let active: Bool
        let nonce: Int64
        let allowSubmit: Bool
        let assets: [Asset]

        struct Asset: Equatable {
            let tokenAddress: TronKit.Address
            let tokenSymbol: String
            let activateFee: BigUInt
            let transferFee: BigUInt
            let decimal: Int
            let frozen: BigUInt
        }

        init(json: [String: Any]) throws {
            guard let accountAddressStr = json["accountAddress"] as? String,
                  let accountAddress = try? TronKit.Address(address: accountAddressStr)
            else {
                throw ProviderError.malformedResponse(field: "accountAddress")
            }
            guard let gasFreeAddressStr = json["gasFreeAddress"] as? String,
                  let gasFreeAddress = try? TronKit.Address(address: gasFreeAddressStr)
            else {
                throw ProviderError.malformedResponse(field: "gasFreeAddress")
            }

            self.accountAddress = accountAddress
            self.gasFreeAddress = gasFreeAddress
            active = json["active"] as? Bool ?? false
            nonce = (json["nonce"] as? NSNumber)?.int64Value ?? 0
            allowSubmit = json["allowSubmit"] as? Bool ?? false

            let assetsJson = json["assets"] as? [[String: Any]] ?? []
            assets = try assetsJson.map { assetJson in
                guard let addressStr = assetJson["tokenAddress"] as? String,
                      let tokenAddress = try? TronKit.Address(address: addressStr)
                else {
                    throw ProviderError.malformedResponse(field: "asset.tokenAddress")
                }
                return Asset(
                    tokenAddress: tokenAddress,
                    tokenSymbol: assetJson["tokenSymbol"] as? String ?? "",
                    activateFee: parseBigUInt(assetJson["activateFee"]) ?? 0,
                    transferFee: parseBigUInt(assetJson["transferFee"]) ?? 0,
                    decimal: assetJson["decimal"] as? Int ?? 0,
                    frozen: parseBigUInt(assetJson["frozen"]) ?? 0
                )
            }
        }
    }

    struct SubmitTransferRequest {
        let token: TronKit.Address
        let serviceProvider: TronKit.Address
        let user: TronKit.Address
        let receiver: TronKit.Address
        let value: BigUInt
        let maxFee: BigUInt
        let deadline: Int64
        let version: Int
        let nonce: Int64
        let signatureHex: String // 0x-prefixed 65-byte hex from TIP-712 signing

        var jsonBody: [String: Any] {
            [
                "token": token.base58,
                "serviceProvider": serviceProvider.base58,
                "user": user.base58,
                "receiver": receiver.base58,
                "value": String(value),
                "maxFee": String(maxFee),
                "deadline": deadline,
                "version": version,
                "nonce": nonce,
                "sig": signatureHex,
            ]
        }
    }

    struct TransferStatus: Equatable {
        let id: String
        let state: String
        let txnHash: String?
        let txnState: String?

        init(json: [String: Any]) throws {
            guard let id = json["id"] as? String else {
                throw ProviderError.malformedResponse(field: "id")
            }
            self.id = id
            state = json["state"] as? String ?? ""
            txnHash = json["txnHash"] as? String
            txnState = json["txnState"] as? String
        }
    }

    enum ProviderError: Error {
        case missingCredentials
        case invalidURL
        case malformedResponse(field: String)
        case api(code: Int, reason: String, message: String)
    }
}

// MARK: - Helpers

private func parseBigUInt(_ value: Any?) -> BigUInt? {
    if let str = value as? String { return BigUInt(str) }
    if let num = value as? NSNumber { return BigUInt(num.uint64Value) }
    return nil
}
