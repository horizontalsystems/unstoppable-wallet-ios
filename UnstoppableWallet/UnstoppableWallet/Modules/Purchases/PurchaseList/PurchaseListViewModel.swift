import Combine
import StoreKit

class PurchaseListViewModel: ObservableObject {
    private let localStorage = App.shared.localStorage
    private let purchaseManager = App.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()

    @Published var activePurchase: PurchaseManager.PurchaseData?

    init() {
        activePurchase = purchaseManager.activePurchase

        purchaseManager.$purchaseData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncActivePurchase() }
            .store(in: &cancellables)
    }

    private func syncActivePurchase() {
        activePurchase = purchaseManager.activePurchase
    }
}

extension PurchaseListViewModel {
    func viewItems(purchase: PurchaseManager.PurchaseData) -> [ViewItem] {
        var viewItems = [ViewItem]()

        let typeValue: String
        var pricePeriod: String?

        var timeTitle: String?
        var timeValue: String?

        switch purchase.type {
        case .lifetime:
            typeValue = "subscription.one-time".localized
            let date = Date(timeIntervalSince1970: purchase.purchaseDate)
            timeValue = DateFormatter.cachedFormatter(format: "dd.MM.yy").string(from: date)
            timeTitle = "subscription.purchase_time".localized
        case .subscription:
            if let expires = purchase.expires {
                typeValue = expires.period.title

                let date = expires.expiresTimestamp.map { Date(timeIntervalSince1970: $0) }
                timeValue = date.map { DateFormatter.cachedFormatter(format: "dd.MM.yy").string(from: $0) }
                timeTitle = "subscription.next_payment".localized
                pricePeriod = expires.period.pricePeriod
            } else {
                typeValue = "subscription.title".localized
            }
        }
        viewItems.append(.init(title: "subscription.type".localized, value: typeValue))

        if let product = purchaseManager.productData.first(where: { $0.id == purchase.id }) {
            viewItems.append(.init(title: "subscription.price".localized, value: [product.priceFormatted, pricePeriod].compactMap { $0 }.joined(separator: "/")))
        }

        if let timeValue, let timeTitle {
            viewItems.append(.init(title: timeTitle, value: timeValue))
        }

        return viewItems
    }

    func onManageSubscriptions() {
        if let window = UIApplication.shared.connectedScenes.first {
            Task { [weak purchaseManager] in
                do {
                    try await AppStore.showManageSubscriptions(in: window as! UIWindowScene)
                    purchaseManager?.loadPurchases()
                } catch {
                    print(error)
                }
            }
        }
    }

    func restorePurchases() {
        purchaseManager.restorePurchases()
    }

    var emulatePurchase: Bool {
        localStorage.emulatePurchase
    }

    func debugCancelSubscription() {
        localStorage.purchaseCancelled = true
        localStorage.purchase = nil

        purchaseManager.loadPurchases()
    }

    func debugClearSubsctiption() {
        localStorage.purchaseCancelled = false
        localStorage.purchase = nil

        purchaseManager.loadPurchases()
    }
}

extension PurchaseListViewModel {
    struct ViewItem: Identifiable {
        let title: String
        let value: String

        var id: String { title }
    }
}
