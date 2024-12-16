import Combine
import StoreKit

private let proFeatures: [PurchasesViewModel.Feature]  = [
    .init(title: "token_insights", iconName: "circle_portfolio_24"),
    .init(title: "advanced_search", iconName: "search_discovery_24"),
    .init(title: "trade_signals", iconName: "bell_ring_24"),
    .init(title: "favorable_swaps", iconName: "precent_24"),
    .init(title: "tx_speed_up", iconName: "outgoing_raw_24"),
    .init(title: "duress_mode", iconName: "switch_wallet_24"),
    .init(title: "address_phishing", iconName: "shield_24"),
    .init(title: "privacy_mode", iconName: "fraud_24"),
]

private let vipFeatures: [PurchasesViewModel.Feature]  = [
    .init(title: "vip_support", iconName: "support_2_24"),
    .init(title: "vip_club", iconName: "support_24"),
]

class PurchasesViewModel: ObservableObject {
    private let purchaseManager = App.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var viewItems: [ViewItem]
    @Published var featuresType: FeaturesType = .pro
    
    @Published private(set) var products: [Product]
    @Published private(set) var purchasedProductIds = Set<String>()

    init() {
        products = purchaseManager.products
        purchasedProductIds = purchaseManager.purchasedProductIds
        viewItems = proFeatures.map { ViewItem(feature: $0) }

        purchaseManager.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.products = $0 }
            .store(in: &cancellables)

        purchaseManager.$purchasedProductIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.purchasedProductIds = $0 }
            .store(in: &cancellables)
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
    
    func setType(_ type: FeaturesType) {
        featuresType = type
        viewItems = (type == .vip ? vipFeatures.map { ViewItem(feature: $0, accented: true) } : []) + proFeatures.map { ViewItem(feature: $0) }
    }
}

extension PurchasesViewModel {
    struct Feature {
        let title: String
        let iconName: String
    }

    enum FeaturesType: String, CaseIterable, Identifiable {
        case pro
        case vip
        
        var icon: String {
            switch self {
                case .pro: return "star_filled_16"
                case .vip: return "crown_16"
            }
        }
        var id: String { rawValue }
    }

    struct ViewItem: Hashable {
        let title: String
        let iconName: String
        let accented: Bool
        
        init(feature: Feature, accented: Bool = false) {
            self.title = feature.title
            self.iconName = feature.iconName
            self.accented = accented
        }
    }
}
