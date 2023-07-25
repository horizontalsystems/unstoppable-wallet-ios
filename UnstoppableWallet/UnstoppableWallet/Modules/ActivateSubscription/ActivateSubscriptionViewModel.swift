import Foundation
import Combine

class ActivateSubscriptionViewModel {
    private let service: ActivateSubscriptionService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var spinnerVisible = true
    @Published private(set) var errorVisible = false
    @Published private(set) var noSubscriptionsVisible = false
    @Published private(set) var viewItem: ViewItem?

    @Published private(set) var signVisible = false
    @Published private(set) var activatingVisible = false
    @Published private(set) var rejectEnabled = true

    init(service: ActivateSubscriptionService) {
        self.service = service

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        service.$activationState
                .sink { [weak self] in self?.sync(activationState: $0) }
                .store(in: &cancellables)

        sync(state: service.state)
        sync(activationState: service.activationState)
    }

    private func sync(state: ActivateSubscriptionService.State) {
        switch state {
        case .loading:
            spinnerVisible = true
            errorVisible = false
            noSubscriptionsVisible = false
            viewItem = nil
        case .noSubscriptions:
            spinnerVisible = false
            errorVisible = false
            noSubscriptionsVisible = true
            viewItem = nil
        case let .readyToActivate(message, account, address):
            spinnerVisible = false
            errorVisible = false
            noSubscriptionsVisible = false
            viewItem = ViewItem(walletName: account.name, address: address.eip55, message: message)
        case .failed:
            spinnerVisible = false
            errorVisible = true
            noSubscriptionsVisible = false
            viewItem = nil
        }
    }

    private func sync(activationState: ActivateSubscriptionService.ActivationState) {
        switch activationState {
        case .ready:
            signVisible = true
            activatingVisible = false
            rejectEnabled = true
        case .activating:
            signVisible = false
            activatingVisible = true
            rejectEnabled = false
        }
    }

}

extension ActivateSubscriptionViewModel {

    var errorPublisher: AnyPublisher<String, Never> {
        service.activationErrorPublisher
                .map { _ in "activate_subscription.failed_to_activate".localized }
                .eraseToAnyPublisher()
    }

    var finishPublisher: AnyPublisher<Void, Never> {
        service.activatedPublisher
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
