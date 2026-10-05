import Combine
import Foundation

class WCDappWhitelist: IWCDappWhitelist {
    private let provider: WhitelistDappProvider
    private let lock = NSLock()
    private var domains = [String]()
    private var loadState = WCWhitelistState.loading
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

    private func set(domains: [String], state: WCWhitelistState) {
        lock.lock()
        self.domains = domains
        loadState = state
        lock.unlock()
    }

    var state: WCWhitelistState {
        lock.lock()
        defer { lock.unlock() }
        return loadState
    }

    func isTrusted(host: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return domains.contains { WCWhitelistMatcher.matches(host: host, allowed: $0) }
    }
}
