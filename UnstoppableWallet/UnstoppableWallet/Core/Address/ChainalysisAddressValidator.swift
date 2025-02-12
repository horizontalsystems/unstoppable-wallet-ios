import Alamofire
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import RxSwift

class ChainalysisAddressValidator {
    private let baseUrl = "https://public.chainalysis.com/api/v1/address/"
    private let networkManager = App.shared.networkManager
    private let headers: HTTPHeaders

    init() {
        headers = HTTPHeaders([
            HTTPHeader(name: "X-API-KEY", value: AppConfig.chainalysisApiKey),
            HTTPHeader(name: "Accept", value: "application/json"),
        ])
    }
}

extension ChainalysisAddressValidator: IAddressSecurityChecker {
    func check(address: Address, token _: Token) async throws -> Bool {
        let response: ChainalysisAddressValidatorResponse = try await networkManager.fetch(url: "\(baseUrl)\(address.raw)", headers: headers)
        return !response.identifications.isEmpty
    }
}

public struct ChainalysisAddressValidatorResponse: ImmutableMappable {
    public let identifications: [Identification]

    public init(map: Map) throws {
        identifications = try map.value("identifications")
    }

    public struct Identification: ImmutableMappable {
        public let category: String
        public let name: String?
        public let description: String?
        public let url: String?

        public init(map: Map) throws {
            category = try map.value("category")
            name = try map.value("name")
            description = try map.value("description")
            url = try map.value("url")
        }
    }
}
