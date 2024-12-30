import Alamofire
import Foundation
import HsToolKit
import ObjectMapper
import RxSwift

class ChainalysisAddressValidator {
    private let baseUrl = "https://public.chainalysis.com/api/v1/address/"
    private let networkManager: NetworkManager
    private let headers: HTTPHeaders

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager

        headers = HTTPHeaders([
            HTTPHeader(name: "X-API-KEY", value: AppConfig.chainalysisApiKey),
            HTTPHeader(name: "Accept", value: "application/json"),
        ])
    }
}

extension ChainalysisAddressValidator: IAddressSecurityCheckerItem {
    func handle(address: Address) -> Single<AddressSecurityCheckerChain.SecurityIssue?> {
        let request = networkManager.session.request("\(baseUrl)\(address.raw)", headers: headers)
        let response: Single<ChainalysisAddressValidatorResponse> = networkManager.single(request: request)

        return response.map {
            if $0.identifications.isEmpty {
                return nil
            }

            return .sanctioned(description: "Sanctioned address. \($0.identifications.count) identifications found.")
        }
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
