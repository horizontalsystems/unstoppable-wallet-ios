import Alamofire
import Combine
import Foundation
import HsToolKit
import ObjectMapper

class SwapProviderInfoManager {
    private let networkManager: NetworkManager
    private let baseUrl = "\(AppConfig.swapApiUrl)/v1"
    private var headers: HTTPHeaders?
    private var cache: [String: ProviderInfo]?
    private var syncTask: Task<Void, Never>?
    private let providerInfoUpdatedSubject = PassthroughSubject<Void, Never>()

    var hasCache: Bool {
        cache != nil
    }

    var providerInfoUpdatedPublisher: AnyPublisher<Void, Never> {
        providerInfoUpdatedSubject.eraseToAnyPublisher()
    }

    init(networkManager: NetworkManager, apiKey: String?) {
        self.networkManager = networkManager

        if let apiKey {
            headers = HTTPHeaders([HTTPHeader(name: "x-api-key", value: apiKey)])
        }
    }

    func info(providerId: String) async -> ProviderInfo? {
        await preload()

        return cachedInfo(providerId: providerId)
    }

    func contacts(providerId: String) -> Contacts? {
        cachedInfo(providerId: providerId)?.contacts
    }

    func preload() async {
        guard cache == nil else {
            return
        }

        startPreload()

        if let syncTask {
            await syncTask.value
        }
    }

    func startPreload() {
        guard cache == nil, syncTask == nil else {
            return
        }

        let syncTask = Task { [weak self] in
            guard let self else {
                return
            }

            await sync()
            self.syncTask = nil
        }
        self.syncTask = syncTask
    }

    private func cachedInfo(providerId: String) -> ProviderInfo? {
        let providerName = providerId.stripping(prefix: "u_").uppercased()
        return cache?[providerName]
    }

    private func sync() async {
        do {
            let responses: [ProviderResponse] = try await networkManager.fetch(url: "\(baseUrl)/providers", headers: headers)
            cache = Dictionary(
                responses.map { ($0.provider.uppercased(), ProviderInfo(provider: $0.provider, contacts: $0.contacts)) },
                uniquingKeysWith: { first, _ in first }
            )
            providerInfoUpdatedSubject.send()
        } catch {
            print(error)
        }
    }
}

extension SwapProviderInfoManager {
    struct ProviderInfo {
        let provider: String
        let contacts: Contacts?
    }

    struct Contacts {
        let email: String?
        let telegram: String?
        let twitter: String?
        let website: String?
    }

    struct ProviderResponse: ImmutableMappable {
        let provider: String
        let contacts: Contacts?

        init(map: Map) throws {
            provider = try map.value("provider")
            contacts = try? Contacts(map: map)
        }
    }
}

extension SwapProviderInfoManager.Contacts: ImmutableMappable {
    init(map: Map) throws {
        email = try? map.value("contacts.email")
        telegram = try? map.value("contacts.telegram")
        twitter = try? map.value("contacts.twitter")
        website = try? map.value("contacts.website")
    }
}
