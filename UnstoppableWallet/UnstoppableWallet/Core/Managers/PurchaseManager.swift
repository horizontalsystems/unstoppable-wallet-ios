import HsExtensions
import StoreKit

class PurchaseManager: NSObject {
    private let productIds = ["trading_1m", "trading_1y", "security_1m", "security_1y", "vip_support_1m", "vip_support_1y"]

    @PostPublished private(set) var products: [Product] = []
    @PostPublished private(set) var purchasedProductIds = Set<String>()

    private var updatesTask: Task<Void, Never>?

    override init() {
        super.init()

        loadProducts()
        loadPurchases()
        observeTransactionUpdates()

        SKPaymentQueue.default().add(self)
    }

    private func loadProducts() {
        Task { [weak self, productIds] in
            let products = try await Product.products(for: productIds)
            self?.products = products

            print(products)
        }
    }

    func loadPurchases() {
        Task { [weak self] in
            await self?.updatePurchasedProducts()
        }
    }

    private func updatePurchasedProducts() async {
        print("UPDATE PURCHASED PRODUCTS")

        for await verificationResult in Transaction.currentEntitlements {
            print("HANDLE FROM UPDATE: \(verificationResult)")
            handle(verificationResult: verificationResult)
        }

        print("FINISH")
    }

    private func observeTransactionUpdates() {
        updatesTask = Task(priority: .background) { [weak self] in
            for await verificationResult in Transaction.updates {
                print("HANDLE FROM OBSERVE: \(verificationResult)")
                self?.handle(verificationResult: verificationResult)
            }

            print("FINISH 2")
        }
    }

    private func handle(verificationResult: VerificationResult<Transaction>) {
        guard case let .verified(transaction) = verificationResult else {
            return
        }

        if transaction.revocationDate == nil {
            purchasedProductIds.insert(transaction.productID)
        } else {
            purchasedProductIds.remove(transaction.productID)
        }
    }
}

extension PurchaseManager {
    func sync() {
        Task {
            try await AppStore.sync()
        }
    }

    func purchase(product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(verificationResult):
            switch verificationResult {
            case let .verified(transaction):
                print("VERIFIED")
                await transaction.finish()
                await updatePurchasedProducts()
            case .unverified:
                print("UNVERIFIED")
                // Successful purchase but transaction/receipt can't be verified
                // Could be a jailbroken phone
            }
        case .pending:
            print("PENDING")
        // Transaction waiting on SCA (Strong Customer Authentication) or
        // approval from Ask to Buy
        case .userCancelled:
            print("USER CANCELLED")
        @unknown default:
            print("UNKNOWN")
        }
    }
}

extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_: SKPaymentQueue, updatedTransactions _: [SKPaymentTransaction]) {
        loadPurchases()
    }

    func paymentQueue(_: SKPaymentQueue, shouldAddStorePayment _: SKPayment, for _: SKProduct) -> Bool {
        return true
    }
}

extension PurchaseManager {
    func check(promocode: String) async throws -> PromoData {
        try await Task.sleep(for: .seconds(2))

        if promocode == "promo" {
            return PromoData(discount: 10)
        } else {
            throw PromoCodeError.invalid
        }
    }
}

extension PurchaseManager {
    enum PromoCodeError: Error {
        case invalid
        case used
    }
    
    struct PromoData {
        let discount: Int
    }
}
