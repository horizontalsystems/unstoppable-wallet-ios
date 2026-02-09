import Alamofire
import Foundation
import HsExtensions
import HsToolKit
import ObjectMapper
import OneInchKit

class MultiSwapProviderManager {
    private let expiration: TimeInterval = 60 * 60

    private let localStorage: LocalStorage
    private let networkManager: NetworkManager

    private let baseUrl = "\(AppConfig.swapApiUrl)/v1"
    private var headers: HTTPHeaders?

    @PostPublished private(set) var providers: [IMultiSwapProvider] = []

    init(localStorage: LocalStorage, networkManager: NetworkManager, apiKey: String?) {
        self.localStorage = localStorage
        self.networkManager = networkManager
        // networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))

        if let apiKey {
            headers = HTTPHeaders([HTTPHeader(name: "x-api-key", value: apiKey)])
        }

        Task { [weak self] in
            self?.syncProviders(uSwapProviderRawValues: localStorage.uSwapProviders.map { $0.components(separatedBy: ",") } ?? [])
        }

        sync()
    }

    private func syncProviders(uSwapProviderRawValues: [String]) {
        let uSwapProviders = uSwapProviderRawValues.compactMap { USwapMultiSwapProvider.Provider(rawValue: $0) }
        providers = Self.providers(uSwapProviders: uSwapProviders)
    }

    func sync() {
        let lastSyncTimetamp = localStorage.swapProvidersLastSyncTimestamp

        if let lastSyncTimetamp, Date().timeIntervalSince1970 - lastSyncTimetamp < expiration {
            return
        }

        Task { [weak self, networkManager, baseUrl, headers] in
            let responses: [ProviderResponse] = try await networkManager.fetch(url: "\(baseUrl)/providers", headers: headers)
            let rawValues = responses.map(\.provider)

            self?.syncProviders(uSwapProviderRawValues: rawValues)
            self?.localStorage.uSwapProviders = rawValues.joined(separator: ",")
            self?.localStorage.swapProvidersLastSyncTimestamp = Date().timeIntervalSince1970
        }
    }
}

extension MultiSwapProviderManager {
    private static func providers(uSwapProviders: [USwapMultiSwapProvider.Provider]) -> [IMultiSwapProvider] {
        var providers: [IMultiSwapProvider] = [
            ThorChainMultiSwapProvider(),
            MayaMultiSwapProvider(),
            AllBridgeMultiSwapProvider(),
        ]

        providers.append(contentsOf: uSwapProviders.map { USwapMultiSwapProvider(provider: $0, apiKey: AppConfig.uswapApiKey) })

        // if let kit = try? UniswapKit.Kit.instance() {
        //     providers.append(UniswapV2MultiSwapProvider(kit: kit))
        //     providers.append(PancakeV2MultiSwapProvider(kit: kit))
        //     providers.append(QuickSwapMultiSwapProvider(kit: kit))
        // }

        // if let kit = try? UniswapKit.KitV3.instance(dexType: .uniswap) {
        //     providers.append(UniswapV3MultiSwapProvider(kit: kit))
        // }

        // if let kit = try? UniswapKit.KitV3.instance(dexType: .pancakeSwap) {
        //     providers.append(PancakeV3MultiSwapProvider(kit: kit))
        // }

        if let apiKey = AppConfig.oneInchApiKey {
            providers.append(OneInchMultiSwapProvider(kit: OneInchKit.Kit.instance(apiKey: apiKey)))
        }

        return providers
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
