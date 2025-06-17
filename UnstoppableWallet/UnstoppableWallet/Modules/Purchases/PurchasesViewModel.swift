import Combine
import StoreKit

class PurchasesViewModel: ObservableObject {
    let approvedIcons: [String] = ["bitcoin", "wallet_scrutiny", "certik"]

    let purchaseManager = Core.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var viewItems: [ViewItem]
    @Published var buttonState: ButtonState = .tryForFree

    var subscribedSuccessful = false

    init() {
        viewItems = PremiumFeature.allCases.map(\.viewItem)
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

    func onSubscribe() {
        subscribedSuccessful = true
    }
}

extension PurchasesViewModel {
    struct Feature {
        let title: String
        let iconName: String
    }

    struct ViewItem: Identifiable, Hashable {
        let title: String
        let iconName: String

        var id: String { title }

        init(feature: Feature) {
            title = feature.title
            iconName = feature.iconName
        }

        init(title: String, iconName: String) {
            self.title = title
            self.iconName = iconName
        }
    }

    enum ButtonState {
        case tryForFree
        case activated
        case upgrade
    }
}

extension PremiumFeature {
    var iconName: String {
        switch self {
        case .vipSupport: return "support_2_24"
        case .tokenInsights: return "circle_portfolio_24"
        case .advancedSearch: return "search_discovery_24"
        case .tradeSignals: return "bell_ring_24"
        case .duressMode: return "duress_24"
        case .addressPhishing: return "circle_check_24"
        case .addressChecker: return "warning_2_24"
        }
    }

    var viewItem: PurchasesViewModel.ViewItem {
        PurchasesViewModel.ViewItem(title: rawValue, iconName: iconName)
    }
}
