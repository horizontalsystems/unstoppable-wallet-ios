import Alamofire
import Foundation
import HsExtensions
import HsToolKit
import ObjectMapper

class MultiSwapProviderManager {
    private let expiration: TimeInterval = 60 * 60

    private let localStorage: LocalStorage
    private let networkManager: NetworkManager

    private let baseUrl = "\(AppConfig.swapApiUrl)/v1"
    private var headers: HTTPHeaders?

    @PostPublished private(set) var providers: [String] = []

    init(localStorage: LocalStorage, networkManager: NetworkManager, apiKey: String?) {
        self.localStorage = localStorage
        self.networkManager = networkManager
        // networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))

        if let apiKey {
            headers = HTTPHeaders([HTTPHeader(name: "x-api-key", value: apiKey)])
        }

        syncProviders(uSwapProviders: localStorage.uSwapProviders.map { $0.components(separatedBy: ",") } ?? [OneInchMultiSwapProvider.id, ThorChainMultiSwapProvider.id, MayaMultiSwapProvider.id, AllBridgeMultiSwapProvider.id])
        sync()
    }

    private func syncProviders(uSwapProviders: [String]) {
        providers = Array(Set([AllBridgeMultiSwapProvider.id/*, JupiterMultiSwapProvider.id*/] + uSwapProviders))
    }

    func sync() {
        let lastSyncTimetamp = localStorage.swapProvidersLastSyncTimestamp

        if let lastSyncTimetamp, Date().timeIntervalSince1970 - lastSyncTimetamp < expiration {
            return
        }

        Task { [weak self, networkManager, baseUrl, headers] in
            let responses: [ProviderResponse] = try await networkManager.fetch(url: "\(baseUrl)/providers", headers: headers)
            let rawValues = responses.map(\.provider)

            self?.syncProviders(uSwapProviders: rawValues)
            self?.localStorage.uSwapProviders = rawValues.joined(separator: ",")
            self?.localStorage.swapProvidersLastSyncTimestamp = Date().timeIntervalSince1970
        }
    }
}

extension MultiSwapProviderManager {
    struct ProviderResponse: ImmutableMappable {
        let provider: String

        init(map: Map) throws {
            provider = try map.value("provider")
        }
    }
}
