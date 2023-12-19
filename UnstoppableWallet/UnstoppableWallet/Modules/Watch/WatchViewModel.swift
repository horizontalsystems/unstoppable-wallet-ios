import Combine
import Foundation
import HsExtensions

class WatchViewModel {
    private let service: WatchService
    private var cancellables = Set<AnyCancellable>()

    @PostPublished private(set) var watchEnabled: Bool = false
    @PostPublished private(set) var name: String
    @PostPublished private(set) var caution: Caution?

    private let proceedSubject = PassthroughSubject<(AccountType, String), Never>()

    init(service: WatchService) {
        self.service = service
        name = service.defaultAccountName

        service.$state
            .sink(receiveValue: { [weak self] in self?.sync(state: $0) })
            .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: WatchService.State) {
        switch state {
        case .ready: watchEnabled = true
        case .notReady: watchEnabled = false
        case let .error(error): caution = Caution(
                text: (error as? LocalizedError)?.errorDescription ?? "watch_address.error.not_supported".localized,
                type: .error
            )
        }
    }

    private func sync(domain: String?) {
        if let domain, service.name == nil {
            service.set(name: domain)
            name = domain
        }
    }
}

extension WatchViewModel {
    var defaultName: String {
        service.defaultAccountName
    }

    var proceedPublisher: AnyPublisher<(AccountType, String), Never> {
        proceedSubject.eraseToAnyPublisher()
    }

    func onChange(text: String) {
        service.set(text: text)
        caution = nil
    }

    func onChange(name: String) {
        service.set(name: name)
    }

    func onTapNext() {
        if let accountType = service.resolve() {
            proceedSubject.send((accountType, service.resolvedName))
        }
    }
}
