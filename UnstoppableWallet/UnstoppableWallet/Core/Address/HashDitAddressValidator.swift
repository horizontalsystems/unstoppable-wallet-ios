import Alamofire
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import RxSwift

class HashDitAddressValidator {
    static let supportedBlockchainTypes: [BlockchainType] = [.ethereum, .binanceSmartChain, .polygon]
    private let url = "https://service.hashdit.io/v2/hashdit/transaction-security"
    private let networkManager = App.shared.networkManager
    private let evmBlockchainManager = App.shared.evmBlockchainManager
    private let headers: HTTPHeaders

    init() {
        headers = HTTPHeaders([
            HTTPHeader(name: "X-API-KEY", value: AppConfig.hashDitApiKey),
            HTTPHeader(name: "Accept", value: "application/json"),
            HTTPHeader(name: "Content-Type", value: "application/json"),
        ])
    }
}

extension HashDitAddressValidator {
    func isClear(address: Address, blockchainType: BlockchainType) async throws -> Bool {
        guard HashDitAddressValidator.supportedBlockchainTypes.contains(blockchainType) else {
            throw CheckError.unsupportedBlockchainType
        }

        let parameters: [String: Any] = [
            "chainId": evmBlockchainManager.chain(blockchainType: blockchainType).id,
            "to": address.raw,
        ]

        let response: HashDitAddressValidatorResponse = try await networkManager.fetch(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)

        return response.data.risk_level < 4
    }
}

extension HashDitAddressValidator: IAddressSecurityChecker {
    func isClear(address: Address, token: Token) async throws -> Bool {
        try await isClear(address: address, blockchainType: token.blockchainType)
    }
}

extension HashDitAddressValidator {
    enum CheckError: Error {
        case unsupportedBlockchainType
    }
}

public struct HashDitAddressValidatorResponse: ImmutableMappable {
    public let code: String
    public let status: String
    public let data: ResponseData

    public init(map: Map) throws {
        code = try map.value("code")
        status = try map.value("status")
        data = try map.value("data")
    }

    public struct ResponseData: ImmutableMappable {
        public let has_result: Bool
        public let risk_level: Int
        public let risk_detail: [RiskDetail]

        public init(map: Map) throws {
            has_result = try map.value("has_result")
            risk_level = try map.value("risk_level")
            risk_detail = try map.value("risk_detail")
        }
    }

    public struct RiskDetail: ImmutableMappable {
        public let name: String
        public let value: String

        public init(map: Map) throws {
            name = try map.value("name")
            value = try map.value("value")
        }
    }
}
