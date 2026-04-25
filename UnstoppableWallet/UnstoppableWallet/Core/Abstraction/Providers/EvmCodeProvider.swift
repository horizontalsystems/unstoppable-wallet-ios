import Alamofire
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper

// TODO: move into EvmKit.Swift package as a public `Kit.fetchCode(address:defaultBlockParameter:)`.
// EvmKit currently exposes fetchStorageAt / fetchCall / fetchEstimateGas but not eth_getCode,
// and the internal fetch<JsonRpc> entry point is not public. Until that lands upstream, this
// provider does the JSON-RPC POST directly via NetworkManager + the chain's RpcSource.
class EvmCodeProvider {
    private let networkManager: NetworkManager
    private let blockchainType: BlockchainType
    private let url: URL
    private let headers: HTTPHeaders

    init(networkManager: NetworkManager, blockchainType: BlockchainType, rpcSource: RpcSource) throws {
        self.networkManager = networkManager
        self.blockchainType = blockchainType

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

extension EvmCodeProvider {
    /// Returns true if the address has contract bytecode at `latest` block.
    /// Used to decide whether the next AA UserOperation needs `initCode` for first-deploy.
    func isDeployed(address: EvmKit.Address) async throws -> Bool {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_getCode",
            "params": [address.eip55, "latest"],
        ]

        let response: GetCodeResponse = try await networkManager.fetch(
            url: url,
            method: .post,
            parameters: payload,
            encoding: JSONEncoding.default,
            headers: headers
        )

        if let error = response.error {
            throw ProviderError.rpc(code: error.code, message: error.message)
        }

        // result is `0x` for an EOA / undeployed address; non-empty hex for contract code.
        guard let hex = response.result else {
            throw ProviderError.rpc(code: -32099, message: "no result")
        }

        return hex != "0x" && !hex.isEmpty
    }
}

extension EvmCodeProvider {
    enum ProviderError: Error {
        case unsupportedRpcSource
        case rpc(code: Int, message: String)
    }
}

private struct GetCodeResponse: ImmutableMappable {
    let result: String?
    let error: RpcError?

    init(map: Map) throws {
        result = try? map.value("result")
        error = try? map.value("error")
    }

    struct RpcError: ImmutableMappable {
        let code: Int
        let message: String

        init(map: Map) throws {
            code = try map.value("code")
            message = try map.value("message")
        }
    }
}
