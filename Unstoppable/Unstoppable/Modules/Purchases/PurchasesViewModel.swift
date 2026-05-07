import Combine
import StoreKit

class PurchasesViewModel: ObservableObject {
    let approvedIcons: [String] = ["bitcoin", "wallet_scrutiny", "certik"]

    let purchaseManager = Core.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()

    let viewItems: [PremiumCategory]

    @Published var buttonState: ButtonState = .tryForFree
    @Published var isSubscriptionSuccessful = false

    init() {
        viewItems = PremiumCategory.allCases
        syncButtonState()
    }

    func loadPurchases() {
        purchaseManager.loadPurchases()
    }

    private func syncButtonState() {
        if case .trial = purchaseManager.introductoryOfferType {
            buttonState = .tryForFree
            return
        }

        buttonState = purchaseManager.hasActivePurchase ? .activated : .upgrade
    }
}

extension PurchasesViewModel {
    func didSubscribeSuccessful() {
        DispatchQueue.main.async { [weak self] in
            self?.isSubscriptionSuccessful = true
        }
    }
}

extension PurchasesViewModel {
    enum ButtonState {
        case tryForFree
        case activated
        case upgrade
    }
}
