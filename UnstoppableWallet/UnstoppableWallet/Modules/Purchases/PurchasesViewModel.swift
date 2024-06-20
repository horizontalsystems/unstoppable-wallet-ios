import Combine
import StoreKit

class PurchasesViewModel: ObservableObject {
    private let purchaseManager = App.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var products: [Product]
    @Published private(set) var purchasedProductIds = Set<String>()

    init() {
        products = purchaseManager.products
        purchasedProductIds = purchaseManager.purchasedProductIds

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
}
