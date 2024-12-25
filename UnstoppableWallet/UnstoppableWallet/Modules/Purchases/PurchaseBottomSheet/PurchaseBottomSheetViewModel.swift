import Combine
import Foundation

class PurchaseBottomSheetViewModel: ObservableObject {
    @Published var selectedPeriod: Period = .annually
    @Published var promoData: PurchaseManager.PromoData = .empty

    private let onSubscribe: ((Period) -> ())
    
    init(onSubscribe: @escaping ((Period) -> ())) {
        self.onSubscribe = onSubscribe
    }

    func onSelect() {
    }
    
    func set(period: Period) {
        selectedPeriod = period
    }
    
    func set(promoData: PurchaseManager.PromoData) {
        self.promoData = promoData
    }
}

extension PurchaseBottomSheetViewModel {
    enum Period: String, CaseIterable, Identifiable {
        case annually
        case monthly
        
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
        
        var price: Decimal {
            switch self {
            case .annually: return 199
            case .monthly: return 24
            }
        }
        
        var pricePeriod: String {
            switch self {
            case .annually: return "purchase.period.year".localized
            case .monthly: return "purchase.period.month".localized
            }
        }
        
        var unitPrice: Decimal? {
            switch self {
            case .annually: return (price / 12).rounded(decimal: 2)
            case .monthly: return nil
            }
        }
        
        var id: String { rawValue }
    }

    struct ViewItem: Hashable {
        let title: String
        let discountBadge: String?
        let price: String
        let priceDescription: String?
        
        init(period: Period) {
            self.title = period.title
            if let discount = period.discount {
                self.discountBadge = ["purchase.period.save".localized.uppercased(), "\(discount)%"].joined(separator: " ")
            } else {
                self.discountBadge = nil
            }
            
            
            self.price = ["US$\(String(describing: period.price))", " / ", period.pricePeriod].joined(separator: " ")
            if let unitPrice = period.unitPrice {
                let price = ["$\(unitPrice)", " / ", "purchase.period.month".localized].joined(separator: " ")
                self.priceDescription = "(\(price))"
            } else {
                self.priceDescription = nil
            }
        }
    }
}
