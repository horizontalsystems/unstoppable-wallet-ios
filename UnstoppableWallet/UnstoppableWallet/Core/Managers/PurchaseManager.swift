import HsExtensions
import StoreKit

class PurchaseManager: NSObject {
    private let productIds = ["trading_1m", "trading_1y", "security_1m", "security_1y", "vip_support_1m", "vip_support_1y"]

    @PostPublished private(set) var products: [Product] = []
    @PostPublished private(set) var purchasedProductIds = Set<String>()

    @PostPublished private(set) var subscription: Subscription? // STUB

    private var updatesTask: Task<Void, Never>?

    override init() {
        super.init()

        loadProducts()
        loadPurchases()
        loadSubscription() // STUB
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
        true
    }
}

extension PurchaseManager {
    // STUB BLOCK
    private static let subscriptionTypeKey = "subscription_type"
    private static let subscriptionPeriodKey = "subscription_period"
    private static let subscriptionTimeKey = "subscription_time"

    func check(promocode: String) async throws -> PromoData {
        if promocode == "" {
            return .empty
        }

        try await Task.sleep(for: .seconds(2))

        if promocode == "promo" {
            return PromoData(promocode: promocode, discount: 10)
        } else {
            throw PromoCodeError.invalid
        }
    }

    func purchase(type: SubscriptionType, period: SubscriptionPeriod) async throws {
        let storage = App.shared.userDefaultsStorage
        let current = Date().timeIntervalSince1970
        storage.set(value: type.rawValue, for: Self.subscriptionTypeKey)
        storage.set(value: period.rawValue, for: Self.subscriptionPeriodKey)
        storage.set(value: current.description, for: Self.subscriptionTimeKey)

        subscription = Subscription(type: type, period: period, timestamp: current)
        try await Task.sleep(for: .seconds(2))
    }

    func deactivate() {
        let storage = App.shared.userDefaultsStorage
        storage.set(value: String?._createNil, for: Self.subscriptionTypeKey)
        storage.set(value: String?._createNil, for: Self.subscriptionPeriodKey)
        storage.set(value: String?._createNil, for: Self.subscriptionTimeKey)

        subscription = nil
    }

    func loadSubscription() {
        let storage = UserDefaultsStorage()
        if let subscriptionType: String = storage.value(for: Self.subscriptionTypeKey),
           let subscriptionPeriod: String = storage.value(for: Self.subscriptionPeriodKey),
           let subscriptionTimeString: String = storage.value(for: Self.subscriptionTimeKey),
           let featureType = SubscriptionType(rawValue: subscriptionType),
           let featurePeriod = SubscriptionPeriod(rawValue: subscriptionPeriod),
           let subscriptionTime = TimeInterval(subscriptionTimeString)
        {
            subscription = Subscription(type: featureType, period: featurePeriod, timestamp: subscriptionTime)
        } else {
            subscription = nil
        }
    }
}

extension PurchaseManager {
    // STUB BLOCK
    enum SubscriptionType: String, CaseIterable {
        case pro
        case vip
    }

    enum SubscriptionPeriod: String, CaseIterable {
        case annually
        case monthly
    }

    struct Subscription: Identifiable {
        let type: SubscriptionType
        let period: SubscriptionPeriod
        let timestamp: TimeInterval

        var id: String {
            [type.rawValue, period.rawValue].joined(separator: "|")
        }
    }

    enum PromoCodeError: Error {
        case invalid
        case used
    }

    struct PromoData {
        static let empty = Self(promocode: "", discount: 0)

        let promocode: String
        let discount: Int
    }
}
