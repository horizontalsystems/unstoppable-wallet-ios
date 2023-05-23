import Foundation
import Combine

class ActivateSubscriptionViewModel {
    private let service: ActivateSubscriptionService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var spinnerVisible = true
    @Published private(set) var errorVisible = false
    @Published private(set) var viewItem: ViewItem?
    @Published private(set) var signVisible = false
    @Published private(set) var activatingVisible = false

    private let errorSubject = PassthroughSubject<String, Never>()
    private let finishSubject = PassthroughSubject<Void, Never>()

    init(service: ActivateSubscriptionService) {
        self.service = service

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        service.$messageItem
                .sink { [weak self] in self?.sync(messageItem: $0) }
                .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: ActivateSubscriptionService.State) {
        switch state {
        case .activated:
            finishSubject.send()
            return
        case .failedToActivate:
            errorSubject.send("activate_subscription.failed_to_activate".localized)
        default: ()
        }

        switch state {
        case .fetchingMessage: spinnerVisible = true
        default: spinnerVisible = false
        }

        switch state {
        case .failedToFetchMessage: errorVisible = true
        default: errorVisible = false
        }

        switch state {
        case .readyToActivate, .failedToActivate: signVisible = true
        default: signVisible = false
        }

        switch state {
        case .activating: activatingVisible = true
        default: activatingVisible = false
        }
    }

    private func sync(messageItem: ActivateSubscriptionService.MessageItem?) {
        viewItem = messageItem.map {
            ViewItem(
                    walletName: $0.account.name,
                    address: $0.address.eip55,
                    message: $0.message
            )
        }
    }

}

extension ActivateSubscriptionViewModel {

    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    func onTapRetry() {
        service.retry()
    }

    func onTapSign() {
        service.sign()
    }

}

extension ActivateSubscriptionViewModel {

    struct ViewItem {
        let walletName: String
        let address: String
        let message: String
    }

}
