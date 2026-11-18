import Combine
import StoreKit

@MainActor
class PurchasesViewModel: ObservableObject {
    let approvedIcons: [String] = ["bitcoin", "wallet_scrutiny", "certik"]
    let features: [PremiumFeature] = PremiumFeature.listed

    let purchaseManager = Core.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()

    @Published var buttonState: ButtonState = .tryForFree
    @Published var isSubscriptionSuccessful = false

    init() {
        syncButtonState()

        Publishers.Merge3(
            purchaseManager.purchaseDataPublisher.map { _ in () },
            purchaseManager.productDataPublisher.map { _ in () },
            purchaseManager.usedOfferProductIdsPublisher.map { _ in () }
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in self?.syncButtonState() }
        .store(in: &cancellables)
    }

    private func syncButtonState() {
        // an active purchase wins over a still-available trial: a lifetime purchase leaves the subscriptions' trial unused
        if purchaseManager.hasActivePurchase {
            buttonState = .activated
        } else if case .trial = purchaseManager.introductoryOfferType {
            buttonState = .tryForFree
        } else {
            buttonState = .upgrade
        }
    }
}

extension PurchasesViewModel {
    func didSubscribeSuccessful() {
        isSubscriptionSuccessful = true
    }
}

extension PurchasesViewModel {
    enum ButtonState {
        case tryForFree
        case activated
        case upgrade
    }
}
