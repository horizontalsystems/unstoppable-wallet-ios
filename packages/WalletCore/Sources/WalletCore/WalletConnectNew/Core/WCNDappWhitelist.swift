import Combine
import Foundation

class WCNDappWhitelist: IWCNDappWhitelist {
    private let provider: WhitelistDappProvider
    private let lock = NSLock()
    private var domains = [String]()
    private var cancellable: AnyCancellable?

    init(provider: WhitelistDappProvider) {
        self.provider = provider
        load()
    }

    private func load() {
        cancellable = provider.whitelistDappsPublisher()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] dApps in
                self?.lock.lock()
                self?.domains = dApps.map(\.url)
                self?.lock.unlock()
            })
    }

    func isTrusted(host: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return domains.contains { WCNWhitelistMatcher.matches(host: host, allowed: $0) }
    }
}
