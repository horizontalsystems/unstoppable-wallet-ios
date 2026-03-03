import Alamofire
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import RxSwift

class HashDitAddressValidator {
    static let supportedBlockchainTypes: [BlockchainType] = [.ethereum, .binanceSmartChain, .polygon]
    private let url = "https://service.hashdit.io/v2/hashdit/address-security-v2"
    private let networkManager = Core.shared.networkManager
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
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

        let parameters: [String: Any] = try [
            "chainId": evmBlockchainManager.chain(blockchainType: blockchainType).id,
            "address": address.raw,
        ]

        let response: HashDitAddressValidatorResponse = try await networkManager.fetch(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)

        guard let score = Int(response.data.overallScore) else {
            throw CheckError.invalidScore
        }

        return score > 60
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
        case invalidScore
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
        public let overallScore: String

        public init(map: Map) throws {
            overallScore = try map.value("overall_score")
        }
    }
}
