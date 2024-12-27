import Combine
import Foundation

class PurchaseBottomSheetViewModel: ObservableObject {
    @Published var selectedPeriod: PurchaseManager.SubscriptionPeriod = .annually
    @Published var promoData: PurchaseManager.PromoData = .empty
    @Published var buttonState: ButtonState = .idle

    private let purchaseManager = App.shared.purchaseManager
    
    let type: PurchaseManager.SubscriptionType
    private let onSubscribe: ((PurchaseManager.SubscriptionPeriod) -> ())

    init(type: PurchaseManager.SubscriptionType, onSubscribe: @escaping ((PurchaseManager.SubscriptionPeriod) -> ())) {
        self.onSubscribe = onSubscribe
        self.type = type
    }

    @MainActor private func update(state: ButtonState) async {
        await MainActor.run { [weak self] in
            self?.buttonState = state
        }
    }

    func subscribe() {
        Task {
            await update(state: .loading)
            
            do {
                try await purchaseManager.purchase(type: type, period: selectedPeriod)
                await update(state: .idle)
                onSubscribe(selectedPeriod)
            } catch {
                print("ERROR: \(error)") // TODO: Handle error
                await update(state: .idle)
            }
        }
    }
    
    func set(period: PurchaseManager.SubscriptionPeriod) {
        selectedPeriod = period
    }
    
    func set(promoData: PurchaseManager.PromoData) {
        self.promoData = promoData
    }
}

extension PurchaseBottomSheetViewModel {
    enum ButtonState {
        case idle
        case loading
    }

    struct ViewItem: Hashable {
        let title: String
        let discountBadge: String?
        let price: String
        let priceDescription: String?
        
        init(type: PurchaseManager.SubscriptionType, period: PurchaseManager.SubscriptionPeriod) {
            self.title = period.title
            if let discount = period.discount {
                self.discountBadge = ["purchase.period.save".localized.uppercased(), "\(discount)%"].joined(separator: " ")
            } else {
                self.discountBadge = nil
            }
            
            
            self.price = ["US$\(String(describing: period.price(type: type)))", " / ", period.pricePeriod].joined(separator: " ")
            if let unitPrice = period.unitPrice(type: type) {
                let price = ["$\(unitPrice)", " / ", "purchase.period.month".localized].joined(separator: " ")
                self.priceDescription = "(\(price))"
            } else {
                self.priceDescription = nil
            }
        }
    }
}

extension PurchaseManager.SubscriptionPeriod: Identifiable {
    var title: String {
        switch self {
        case .annually: return "purchase.period.annually".localized
        case .monthly: return "purchase.period.monthly".localized
        }
    }
    
    var discount: Int? {
        switch self {
        case .annually: return 45
        case .monthly: return nil
        }
    }
    
    func price(type: PurchaseManager.SubscriptionType) -> Decimal {
        switch self {
        case .annually: return type == .pro ? 199 : 660
        case .monthly: return type == .pro ? 24 : 80
        }
    }
    
    var pricePeriod: String {
        switch self {
        case .annually: return "purchase.period.year".localized
        case .monthly: return "purchase.period.month".localized
        }
    }
    
    func unitPrice(type: PurchaseManager.SubscriptionType) -> Decimal? {
        switch self {
        case .annually: return (price(type: type) / 12).rounded(decimal: 2)
        case .monthly: return nil
        }
    }
    
    var id: String { rawValue }
}
