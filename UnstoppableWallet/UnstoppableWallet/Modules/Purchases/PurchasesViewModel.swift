import Combine
import StoreKit

class PurchasesViewModel: ObservableObject {
    private static let proFeatures: [PurchasesViewModel.Feature] = [
        .init(title: "token_insights", iconName: "circle_portfolio_24"),
        .init(title: "advanced_search", iconName: "search_discovery_24"),
        .init(title: "trade_signals", iconName: "bell_ring_24"),
        .init(title: "tx_speed_up", iconName: "outgoing_raw_24"),
        .init(title: "duress_mode", iconName: "switch_wallet_24"),
        .init(title: "address_phishing", iconName: "shield_24"),
        .init(title: "address_checker", iconName: "warning_2_24"),
        .init(title: "privacy_mode", iconName: "fraud_24"),
    ]

    static let vipFeatures: [PurchasesViewModel.Feature] = [
        .init(title: "vip_support", iconName: "support_2_24"),
        .init(title: "vip_club", iconName: "support_24"),
    ]

    let approvedIcons: [String] = ["bitcoin", "wallet_scrutiny", "certik"]

    private let purchaseManager = App.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var viewItems: [ViewItem]
    @Published var buttonState: ButtonState = .tryForFree

    @Published var featuresType: PurchaseManager.SubscriptionType = .pro
    var subscribedSuccessful = false

    @Published private(set) var products: [Product]
    @Published private(set) var purchasedProductIds = Set<String>()

    init() {
        products = purchaseManager.products
        purchasedProductIds = purchaseManager.purchasedProductIds
        viewItems = Self.proFeatures.map { ViewItem(feature: $0) }

        purchaseManager.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.products = $0 }
            .store(in: &cancellables)

        purchaseManager.$purchasedProductIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.purchasedProductIds = $0 }
            .store(in: &cancellables)

        syncButtonState()
    }

    func purchase(product: Product) {
        Task { [purchaseManager] in
            do {
                try await purchaseManager.purchase(product: product)
            } catch {
                print(error)
            }
        }
    }

    func restorePurchases() {
        purchaseManager.sync()
    }

    func loadPurchases() {
        purchaseManager.loadPurchases()
    }

    func setType(_ type: PurchaseManager.SubscriptionType) {
        featuresType = type
        viewItems = (type == .vip ? Self.vipFeatures.map { ViewItem(feature: $0, accented: true) } : []) + Self.proFeatures.map { ViewItem(feature: $0) }
        syncButtonState()
    }

    private func syncButtonState() {
        guard let subscription = purchaseManager.subscription else {
            buttonState = .tryForFree
            return
        }

        switch subscription.type {
        case .pro:
            buttonState = featuresType == .pro ? .activated : .upgrade
        case .vip:
            buttonState = .activated // TODO: if vip activated and selected pro which button title will be?
        }
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
        let accented: Bool

        var id: String { title }

        init(feature: Feature, accented: Bool = false) {
            title = feature.title
            iconName = feature.iconName
            self.accented = accented
        }
    }

    enum ButtonState {
        case tryForFree
        case activated
        case upgrade
    }
}

extension PurchaseManager.SubscriptionType: Identifiable {
    var icon: String {
        switch self {
        case .pro: return "star_filled_16"
        case .vip: return "crown_16"
        }
    }

    var id: String { rawValue }
}
