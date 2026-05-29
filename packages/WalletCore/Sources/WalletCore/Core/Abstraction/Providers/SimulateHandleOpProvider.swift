import Alamofire
import BigInt
import EvmKit
import Foundation
import HsExtensions
import HsToolKit
import MarketKit
import ObjectMapper

/// Calls `EntryPoint.simulateHandleOp` directly via the chain's execution RPC. The method
/// ALWAYS reverts; on a successful simulation the revert data carries the `ExecutionResult`
/// custom error from which `paid` (actualGasCost in wei) is extracted. Used to derive a
/// realistic estimated fee in tokens — Pimlico's bundler-side `eth_estimateUserOperationGas`
/// returns gas LIMITS with safety margins (often ~2x real usage), not the actual cost.
class SimulateHandleOpProvider {
    private let networkManager: NetworkManager
    private let entryPoint: EvmKit.Address
    private let url: URL
    private let headers: HTTPHeaders

    init(networkManager: NetworkManager, entryPoint: EvmKit.Address, rpcSource: RpcSource) throws {
        self.networkManager = networkManager
        self.entryPoint = entryPoint

        guard case let .http(urls, auth) = rpcSource, let firstUrl = urls.first else {
            throw ProviderError.unsupportedRpcSource
        }

        url = firstUrl

        var headers: [HTTPHeader] = [HTTPHeader(name: "Content-Type", value: "application/json")]
        if let auth {
            headers.append(HTTPHeader(name: "Authorization", value: "Basic \(auth)"))
        }
        self.headers = HTTPHeaders(headers)
    }
}

extension SimulateHandleOpProvider {
    func simulate(userOp: UserOperation) async throws -> EntryPointV06.SimulationResult {
        let calldata = EntryPointV06.encodeSimulateHandleOp(userOp)
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_call",
            "params": [
                [
                    "to": entryPoint.eip55,
                    "data": "0x" + calldata.hs.hex,
                ],
                "latest",
            ],
        ]

        let response: SimulateResponse = try await networkManager.fetch(
            url: url,
            method: .post,
            parameters: payload,
            encoding: JSONEncoding.default,
            headers: headers
        )

        // simulateHandleOp ALWAYS reverts. Some RPC providers return non-error result with the
        // revert payload encoded as a hex string; most return error.data with the same payload.
        // Prefer error.data when present, fall back to result.
        if let data = response.error?.data.flatMap(Self.extractHex) {
            return try EntryPointV06.decodeSimulationResult(revertData: data)
        }
        if let result = response.result, let data = Self.extractHex(result) {
            return try EntryPointV06.decodeSimulationResult(revertData: data)
        }

        if let error = response.error {
            throw ProviderError.rpc(code: error.code, message: error.message)
        }
        throw ProviderError.rpc(code: -32099, message: "no revert data")
    }

    /// Extracts a leading "0x..."-prefixed hex blob from a string. Some RPC providers wrap the
    /// revert data as `"Reverted 0x..."` or `"execution reverted: 0x..."`; this finds the hex.
    private static func extractHex(_ raw: String) -> Data? {
        guard let range = raw.range(of: "0x", options: .caseInsensitive) else {
            return nil
        }
        return String(raw[range.lowerBound...]).hs.hexData
    }
}

extension SimulateHandleOpProvider {
    enum ProviderError: Error {
        case unsupportedRpcSource
        case rpc(code: Int, message: String)
    }
}

private struct SimulateResponse: ImmutableMappable {
    let result: String?
    let error: SimulateRpcError?

    init(map: Map) throws {
        result = try? map.value("result")
        error = try? map.value("error")
    }
}

private struct SimulateRpcError: ImmutableMappable {
    let code: Int
    let message: String
    let data: String?

    init(map: Map) throws {
        code = try map.value("code")
        message = try map.value("message")
        // Some providers send `data` as a hex string, others as an object with nested fields.
        // Try string first; if that fails, extract from a nested `data` field.
        if let str: String = try? map.value("data") {
            data = str
        } else if let nested: [String: Any] = try? map.value("data"), let inner = nested["data"] as? String {
            data = inner
        } else {
            data = nil
        }
    }
}
