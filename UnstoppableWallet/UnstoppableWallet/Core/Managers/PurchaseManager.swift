import HsExtensions
import StoreKit

class PurchaseManager: NSObject {
    private let offerUpdateQueue = DispatchQueue(label: "\(AppConfig.label).unstoppable-wallet.offer-update", qos: .userInitiated)
    private let dataAccessQueue = DispatchQueue(label: "\(AppConfig.label).data-access", qos: .userInitiated)

    static let productName = "premium"
    static let productIds = PurchaseType.allCases.flatMap { $0.variants.map { id(productName, $0) }}

    static func id(_ f: String, _ s: String) -> String {
        [f, s].joined(separator: "_")
    }

    @PostPublished private(set) var products: [Product] = []
    @PostPublished private(set) var purchasedProducts = [String: Transaction]()

    @PostPublished private(set) var productData = [ProductData]()
    @PostPublished private(set) var purchaseData = [PurchaseData]()

    @PostPublished private(set) var activeFeatures = [PremiumFeature]()
    @PostPublished private(set) var usedOfferProductIds = Set<String>()

    private var updatesTask: Task<Void, Never>?
    private var currentUsedOfferUpdateTask: Task<Void, Never>?

    override init() {
        super.init()

        loadProducts()
        loadPurchases()
        observeTransactionUpdates()

        SKPaymentQueue.default().add(self)
    }

    private func loadProducts() {
        Task { [weak self] in
            guard let self else { return }
            let products = try await Product.products(for: Self.productIds)

            dataAccessQueue.sync {
                self.products = products.sorted(by: { $0.price > $1.price })
                //             print(products.sorted(by: { $0.price > $1.price }))

                self.syncProducts()
            }
        }
    }

    func loadPurchases() {
        Task { [weak self] in
            await self?.updatePurchasedProducts()
        }
    }

    private func updatePurchasedProducts() async {
        for await verificationResult in Transaction.currentEntitlements {
            handle(verificationResult: verificationResult)
        }
    }

    private func observeTransactionUpdates() {
        updatesTask = Task(priority: .background) { [weak self] in
            for await verificationResult in Transaction.updates {
                self?.handle(verificationResult: verificationResult)
            }
        }
    }

    private func handle(verificationResult: VerificationResult<Transaction>) {
        guard case let .verified(transaction) = verificationResult else {
            return
        }

        dataAccessQueue.sync {
            if transaction.revocationDate == nil {
                purchasedProducts[transaction.productID] = transaction
            } else {
                purchasedProducts[transaction.productID] = nil
            }
            syncPurchases()
        }
    }

    private func syncProducts() {
        productData = products.compactMap { ProductData(product: $0) }
        //        print(productData)
    }

    func checkTrialHistoryUsage() async -> Bool {
        for await verificationResult in Transaction.all {
            if case let .verified(transaction) = verificationResult {
                if let offerType = transaction.offerType,
                   offerType == .introductory,
                   transaction.productID.starts(with: Self.productName)
                {
                    return true
                }
            }
        }
        return false
    }

    private func syncPurchases() {
        purchaseData = purchasedProducts
            .values
            .compactMap { PurchaseData(transaction: $0) }
            .sorted { $0.type.order < $1.type.order }

//        print(purchaseData)

        activeFeatures = activePurchase != nil ? PremiumFeature.allCases : []

        syncUsedOffers()
    }

    private func syncUsedOffers() {
        currentUsedOfferUpdateTask?.cancel()

        offerUpdateQueue.async { [weak self] in
            guard let self else { return }

            currentUsedOfferUpdateTask = Task(priority: .background) { [weak self] in
                await self?.updateUsedOffers()
            }

            if let task = currentUsedOfferUpdateTask {
                Task {
                    await task.value
                }
            }
        }
    }

    func getJws() async -> String? {
        guard let purchase = activePurchase else {
            return nil
        }

        let result = await Transaction.currentEntitlements.first(where: {
            switch $0 {
            case let .verified(transaction): return transaction.productID == purchase.id
            default: return false
            }
        })

        return result?.jwsRepresentation
    }
}

extension PurchaseManager {
    func restorePurchases() {
        Task {
            try await AppStore.sync()
        }
    }

    func purchase(product: ProductData) async throws {
        if let product = products.first(where: { $0.id == product.id }) {
            try await purchase(product: product)
        } else {
            throw SubscribeError.cantFoundProduct
        }
    }

    @MainActor
    func purchase(product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(verificationResult):
            switch verificationResult {
            case let .verified(transaction):
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
            throw SubscribeError.userCancelled
        @unknown default:
            print("UNKNOWN")
        }
    }
}

extension PurchaseManager {
    var activePurchase: PurchaseData? {
        purchaseData.first {
            if let expiresTimestamp = $0.expires, let timestamp = expiresTimestamp.expiresTimestamp {
                return timestamp > Date().timeIntervalSince1970
            }
            return true
        }
    }

    var hasActivePurchase: Bool {
        activePurchase != nil
    }

    var introductoryOfferType: IntroductoryOfferType {
        var offers: [IntroductoryOfferType] = []
        for product in productData {
            if usedOfferProductIds.contains(product.id) {
                offers.append(.none)
                continue
            }
            offers.append(IntroductoryOfferType(product.introductoryOffer))
        }
        return offers.sorted(by: <).first ?? .none
    }

    func activated(_ premiumFeature: PremiumFeature) -> Bool {
        activeFeatures.contains(premiumFeature)
    }

    func updateUsedOffers() async {
        var usedOfferProductIds = Set<String>()
        offerUpdateQueue.sync {
            usedOfferProductIds = self.usedOfferProductIds
        }

        if productData.isEmpty {
            return
        }

        for product in productData {
            // if product already in list, nothing can changes
            guard !usedOfferProductIds.contains(product.id) else {
                continue
            }

            // there are no any introducery offers for purchases
            guard product.type == .subscription else {
                continue
            }

            // there are no any offers by product
            guard product.introductoryOffer != nil else {
                continue
            }

            let productId = product.id

            // check active subscriptions
            if let product = products.first(where: { $0.id == productId }),
               let subscription = product.subscription,
               await subscription.isEligibleForIntroOffer == false
            {
                usedOfferProductIds.insert(productId)
                continue
            }

            // if previous was not corrected
            if await hasUsedIntroOffer(for: productId) {
                usedOfferProductIds.insert(productId)
            }
        }

        offerUpdateQueue.sync {
            // print("Used Products: \(usedOfferProductIds)")
            self.usedOfferProductIds = usedOfferProductIds
        }
    }

    // Check for trial offer usage history
    private func hasUsedIntroOffer(for productId: String) async -> Bool {
        var seenProductTypes = Set<PurchaseType>()

        // Check all transactions for used trial offers
        for await result in Transaction.all {
            if case let .verified(transaction) = result {
                // Get product type
                guard let transactionPurchaseType = PurchaseType(id: transaction.productID),
                      let productPurchaseType = PurchaseType(id: productId)
                else {
                    continue
                }

                // Only check transactions of the same subscription type
                if transactionPurchaseType != productPurchaseType {
                    continue
                }

                // Add type to the set of seen products
                seenProductTypes.insert(transactionPurchaseType)

                // Check if this was a transaction with an introductory offer
                let wasIntroOffer: Bool

                if #available(iOS 17.2, *) {
                    wasIntroOffer = transaction.offer?.type == .introductory
                } else {
                    wasIntroOffer = transaction.offerType == .introductory
                }

                if wasIntroOffer {
                    return true // Trial was already used for this product type
                }
            }
        }

        // Additional check: if we saw transactions of this type,
        // but none were introOffer, this might mean the user
        // purchased the product directly without a trial
        if !seenProductTypes.isEmpty {
            // In this case we consider that trial was "skipped"
            return true
        }

        return false // No used trial periods or transactions of this type found
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
    enum PurchaseType: String, CaseIterable {
        case lifetime
        case subscription

        var variants: [String] {
            switch self {
            case .lifetime: return ["lifetime"]
            case .subscription: return SubscriptionPeriod.allCases.map(\.rawValue)
            }
        }

        init?(id: String) {
            if id.contains(Self.lifetime.rawValue) {
                self = .lifetime
            } else if SubscriptionPeriod.allCases.map({ PurchaseManager.id(PurchaseManager.productName, $0.rawValue) }).contains(id) {
                self = .subscription
            } else {
                return nil
            }
        }

        var order: Int {
            switch self {
            case .lifetime: return 0
            case .subscription: return 1
            }
        }
    }

    enum SubscriptionPeriod: String, CaseIterable {
        case monthly = "1m"
        case annually = "1y"

        var productName: String {
            PurchaseManager.id(PurchaseManager.productName, rawValue)
        }

        init?(id: String) {
            for period in SubscriptionPeriod.allCases {
                if id == period.productName {
                    self = period
                    return
                }
            }
            return nil
        }
    }

    enum SubscribeError: Error {
        case cantFoundProduct
        case userCancelled
    }

    struct ExpiresData {
        let period: SubscriptionPeriod
        let expiresTimestamp: TimeInterval?
    }

    struct Discount {
        let periodCount: Int
        let price: Decimal
        let priceFormatted: String
    }

    enum IntroductoryOfferType: Int, Comparable {
        public static let `default` = Self.none

        case trial, discount, none

        public static func == (lhs: IntroductoryOfferType, rhs: IntroductoryOfferType) -> Bool {
            lhs.rawValue == rhs.rawValue
        }

        public static func < (lhs: IntroductoryOfferType, rhs: IntroductoryOfferType) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        init(_ offer: Product.SubscriptionOffer?) {
            switch offer?.paymentMode {
            case .none: self = .none
            case .freeTrial: self = .trial
            default: self = .discount
            }
        }
    }

    struct ProductData {
        let id: String
        let type: PurchaseType
        let period: SubscriptionPeriod?

        let price: Decimal
        let priceFormatted: String

        let introductoryOffer: Product.SubscriptionOffer?
        var hasTrialPeriod: Bool {
            if let paymentMode = introductoryOffer?.paymentMode {
                return paymentMode == .freeTrial
            }
            return false
        }

        var introductoryDiscount: Discount? {
            if let paymentMode = introductoryOffer?.paymentMode,
               paymentMode != .freeTrial,
               let offerPrice = introductoryOffer?.price,
               let offerPeriods = introductoryOffer?.periodCount,
               let priceFormatted = introductoryOffer?.displayPrice
            {
                return Discount(periodCount: offerPeriods, price: offerPrice, priceFormatted: priceFormatted)
            }
            return nil
        }

        init?(product: Product) {
            id = product.id

            guard let type = PurchaseType(id: product.id) else {
                return nil
            }

            switch type {
            case .lifetime:
                self.type = .lifetime
                period = nil
            case .subscription:
                self.type = .subscription
                period = SubscriptionPeriod(id: product.id)
            }
            priceFormatted = product.displayPrice
            price = product.price
            introductoryOffer = product.subscription?.introductoryOffer
        }
    }

    struct PurchaseData {
        let id: String
        let type: PurchaseType
        let purchaseDate: TimeInterval
        let offerType: Transaction.OfferType?
        let expires: ExpiresData?

        init(id: String, type: PurchaseType, purchaseDate: TimeInterval, offerType: Transaction.OfferType?, expiresTimestamp: ExpiresData? = nil) {
            self.id = id
            self.type = type
            self.purchaseDate = purchaseDate
            self.offerType = offerType
            expires = expiresTimestamp
        }

        init?(transaction: Transaction) {
            id = transaction.productID

            guard let type = PurchaseType(id: id) else {
                return nil
            }
            self.type = type
            purchaseDate = transaction.purchaseDate.timeIntervalSince1970
            if #available(iOS 17.2, *) {
                offerType = transaction.offer?.type
            } else {
                offerType = transaction.offerType
            }

            if let expiresTimestamp = transaction.expirationDate?.timeIntervalSince1970, let period = SubscriptionPeriod(id: id) {
                expires = ExpiresData(period: period, expiresTimestamp: expiresTimestamp)
            } else {
                expires = nil
            }
        }
    }
}

enum PremiumFeature: String, CaseIterable {
    case tokenInsights = "token_insights"
    case advancedSearch = "advanced_search"
    case tradeSignals = "trade_signals"
    case duressMode = "duress_mode"
    case addressPhishing = "address_phishing"
    case addressChecker = "address_checker"
    case vipSupport = "vip_support"
}
