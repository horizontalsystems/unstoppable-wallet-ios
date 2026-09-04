import Combine
import Foundation

class WCNDappWhitelist: IWCNDappWhitelist {
    private let provider: WhitelistDappProvider
    private let lock = NSLock()
    private var domains = [String]()
    private var loadState = WCNWhitelistState.loading
    private var cancellable: AnyCancellable?

    init(provider: WhitelistDappProvider) {
        self.provider = provider
        load()
    }

    private func load() {
        cancellable = provider.whitelistDappsPublisher()
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.set(domains: [], state: .unavailable)
                }
            }, receiveValue: { [weak self] dApps in
                self?.set(domains: dApps.map(\.url), state: .loaded)
            })
    }

    private func set(domains: [String], state: WCNWhitelistState) {
        lock.lock()
        self.domains = domains
        loadState = state
        lock.unlock()
    }

    var state: WCNWhitelistState {
        lock.lock()
        defer { lock.unlock() }
        return loadState
    }

    func isTrusted(host: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return domains.contains { WCNWhitelistMatcher.matches(host: host, allowed: $0) }
    }
}
