import Combine
import HsExtensions
import StoreKit

class PurchaseManager: NSObject {
    private let localStorage: LocalStorage

    /// Guards all purchase state below: every read and write of it goes through this queue. The `...Locked`
    /// members expect to run on it already and are never called from outside it.
    private let dataAccessQueue = DispatchQueue(label: "\(AppConfig.label).data-access", qos: .userInitiated)

    static let productName = "premium"
    static let productIds = PurchaseType.allCases.flatMap { $0.variants.map { id(productName, $0) }}

    static func id(_ f: String, _ s: String) -> String {
        [f, s].joined(separator: "_")
    }

    private var products: [Product] = []
    private var purchasedProducts = [String: Transaction]()
    /// Ids of transactions seen revoked: a stale entitlements snapshot must not record them again
    private var revokedTransactionIds = Set<UInt64>()

    @PostPublished private var productDataValue = [ProductData]()
    @PostPublished private var purchaseDataValue = [PurchaseData]()
    @PostPublished private var activeFeaturesValue = [PremiumFeature]()
    @PostPublished private var usedOfferProductIdsValue = Set<String>()

    private var updatesTask: Task<Void, Never>?
    private var currentUsedOfferUpdateTask: Task<Void, Never>?
    private var usedOffersGeneration = 0

    init(localStorage: LocalStorage) {
        self.localStorage = localStorage

        super.init()

        loadProducts()
        loadPurchases()
        observeTransactionUpdates()

        SKPaymentQueue.default().add(self)
    }

    /// The debug "emulate purchase" switch, honoured only in builds that show the dev tools
    private var isEmulating: Bool {
        localStorage.emulatePurchase && AppConfig.showDevTools
    }

    func loadProducts() {
        Task { [weak self] in
            guard let self else { return }
            let products = try await Product.products(for: Self.productIds)

            dataAccessQueue.sync {
                self.products = products.sorted(by: { $0.price > $1.price })
                self.syncProductsLocked()
                // the used-offer check needs the products, and a run made before they loaded returned early
                self.syncUsedOffersLocked()
            }
        }
    }

    func loadPurchases() {
        if isEmulating {
            dataAccessQueue.sync {
                syncPurchasesLocked()
            }
        }

        Task { [weak self] in
            await self?.updatePurchasedProducts()
        }
    }

    /// Adds or updates recorded purchases from the current entitlements. It never removes an entry the list lacks:
    /// right after a purchase the list can lag behind it. Expiry is checked when a purchase is read.
    private func updatePurchasedProducts() async {
        var entitlements = [Transaction]()

        for await verificationResult in Transaction.currentEntitlements {
            if case let .verified(transaction) = verificationResult {
                entitlements.append(transaction)
            }
        }

        dataAccessQueue.sync {
            for transaction in entitlements {
                applyLocked(transaction)
            }

            syncPurchasesLocked()
        }
    }

    private func observeTransactionUpdates() {
        updatesTask = Task(priority: .background) { [weak self] in
            for await verificationResult in Transaction.updates {
                self?.record(verificationResult: verificationResult)
            }
        }
    }

    private func record(verificationResult: VerificationResult<Transaction>) {
        guard case let .verified(transaction) = verificationResult else {
            return
        }

        dataAccessQueue.sync {
            applyLocked(transaction)
            syncPurchasesLocked()
        }
    }

    private func applyLocked(_ transaction: Transaction) {
        let applied = PurchaseEntitlements.applying(transaction, to: purchasedProducts, revokedIds: revokedTransactionIds)
        purchasedProducts = applied.recorded
        revokedTransactionIds = applied.revokedIds

        if applied.cleared {
            // the revoked transaction was the recorded one: the current list may hold another valid one for the product
            Task { [weak self] in
                await self?.updatePurchasedProducts()
            }
        }
    }

    private func syncProductsLocked() {
        guard !isEmulating else {
            productDataValue = ProductData.testProducts
            return
        }
        productDataValue = products.compactMap { ProductData(product: $0) }
    }

    private func checkTrialHistoryUsage() async -> Bool {
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

    private func syncPurchasesLocked() {
        if isEmulating {
            purchaseDataValue = [localStorage.purchase].compactMap { $0 }
        } else {
            purchaseDataValue = purchasedProducts
                .values
                .compactMap { PurchaseData(transaction: $0) }
                .sorted { $0.type.order < $1.type.order }
        }

        activeFeaturesValue = activePurchaseLocked != nil ? PremiumFeature.allCases : []

        syncUsedOffersLocked()
    }

    /// The cancel, the new run and its generation are all set on `dataAccessQueue`, and a run writes its result
    /// only while it is still the latest, so an older run can never overwrite a newer one
    private func syncUsedOffersLocked() {
        currentUsedOfferUpdateTask?.cancel()

        usedOffersGeneration += 1
        let generation = usedOffersGeneration

        currentUsedOfferUpdateTask = Task(priority: .background) { [weak self] in
            await self?.updateUsedOffers(generation: generation)
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
    var productData: [ProductData] {
        dataAccessQueue.sync { productDataValue }
    }

    var purchaseData: [PurchaseData] {
        dataAccessQueue.sync { purchaseDataValue }
    }

    var usedOfferProductIds: Set<String> {
        dataAccessQueue.sync { usedOfferProductIdsValue }
    }

    // Values are sent on `dataAccessQueue`: a subscriber must hop off it (e.g. `.receive(on: DispatchQueue.main)`)
    // before it reads any of the accessors above, which would otherwise sync on the queue it is already on

    var productDataPublisher: AnyPublisher<[ProductData], Never> {
        $productDataValue
    }

    var purchaseDataPublisher: AnyPublisher<[PurchaseData], Never> {
        $purchaseDataValue
    }

    var activeFeaturesPublisher: AnyPublisher<[PremiumFeature], Never> {
        $activeFeaturesValue
    }

    var usedOfferProductIdsPublisher: AnyPublisher<Set<String>, Never> {
        $usedOfferProductIdsValue
    }
}

extension PurchaseManager {
    func restorePurchases() {
        Task {
            try await AppStore.sync()
        }
    }

    /// Returns `.purchased` only for a verified purchase that is already recorded. A `.pending` purchase
    /// (Ask to Buy, SCA) is recorded later from `Transaction.updates` and published through `purchaseData`.
    @discardableResult
    func purchase(product: ProductData) async throws -> PurchaseOutcome {
        guard !isEmulating else { // emulate subscription
            localStorage.purchaseCancelled = false
            localStorage.purchase = PurchaseData(product: product)

            dataAccessQueue.sync {
                syncPurchasesLocked()
            }
            return .purchased
        }

        let storeProduct = dataAccessQueue.sync { products.first(where: { $0.id == product.id }) }

        if let storeProduct {
            return try await purchase(product: storeProduct)
        } else {
            throw SubscribeError.cantFoundProduct
        }
    }

    @MainActor
    private func purchase(product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()

        switch result {
        case let .success(verificationResult):
            switch verificationResult {
            case let .verified(transaction):
                // Record the purchase from the transaction itself: right after a purchase
                // `Transaction.currentEntitlements` is not guaranteed to contain it yet
                record(verificationResult: verificationResult)
                await transaction.finish()
                await updatePurchasedProducts()
                return .purchased
            case .unverified:
                // Successful purchase but transaction/receipt can't be verified
                // Could be a jailbroken phone
                throw SubscribeError.unverified
            }
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            return .pending
        case .userCancelled:
            throw SubscribeError.userCancelled
        @unknown default:
            throw SubscribeError.unknownResult
        }
    }
}

extension PurchaseManager {
    var activePurchase: PurchaseData? {
        dataAccessQueue.sync { activePurchaseLocked }
    }

    var hasActivePurchase: Bool {
        activePurchase != nil
    }

    var introductoryOfferType: IntroductoryOfferType {
        dataAccessQueue.sync { introductoryOfferTypeLocked }
    }

    /// Re-checks expiry on every call: a subscription that expires while the app runs stops unlocking features
    func activated(_ premiumFeature: PremiumFeature) -> Bool {
        dataAccessQueue.sync {
            activePurchaseLocked != nil && activeFeaturesValue.contains(premiumFeature)
        }
    }

    private var activePurchaseLocked: PurchaseData? {
        var purchases = purchaseDataValue
        if isEmulating { // emulate purchase from localStorage
            purchases = [localStorage.purchase].compactMap { $0 }
        }

        return purchases.first {
            if let expiresTimestamp = $0.expires, let timestamp = expiresTimestamp.expiresTimestamp {
                return timestamp > Date().timeIntervalSince1970
            }
            return true
        }
    }

    private var introductoryOfferTypeLocked: IntroductoryOfferType {
        var offers: [IntroductoryOfferType] = []

        if isEmulating {
            return localStorage.purchaseCancelled ? .none : .trial
        }

        for product in productDataValue {
            if usedOfferProductIdsValue.contains(product.id) {
                offers.append(.none)
                continue
            }
            offers.append(IntroductoryOfferType(product.introductoryOffer))
        }
        return offers.sorted(by: <).first ?? .none
    }

    private func updateUsedOffers(generation: Int) async {
        let (known, productData, products, emulating, purchaseCancelled) = dataAccessQueue.sync {
            (usedOfferProductIdsValue, productDataValue, self.products, isEmulating, localStorage.purchaseCancelled)
        }

        if productData.isEmpty {
            return
        }

        var usedIds = known

        if emulating { // if emulate and cancelled - all product must ignore trial period
            usedIds = purchaseCancelled ? Set(productData.map(\.id)) : Set()
        } else {
            for product in productData {
                guard !Task.isCancelled else {
                    return
                }

                // if product already in list, nothing can changes
                guard !usedIds.contains(product.id) else {
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
                    usedIds.insert(productId)
                    continue
                }

                // if previous was not corrected
                if await hasUsedIntroOffer(for: productId) {
                    usedIds.insert(productId)
                }
            }
        }

        guard !Task.isCancelled else {
            return
        }

        dataAccessQueue.sync {
            // a newer run started meanwhile: only its result is written
            guard generation == usedOffersGeneration else {
                return
            }

            usedOfferProductIdsValue = usedIds
        }
    }

    /// Check for trial offer usage history
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
    enum PurchaseType: String, Codable, CaseIterable {
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

    enum SubscriptionPeriod: String, Codable, CaseIterable {
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
        case unverified
        case unknownResult
    }

    enum PurchaseOutcome {
        case purchased
        case pending
    }

    struct ExpiresData: Codable {
        let period: SubscriptionPeriod
        let expiresTimestamp: TimeInterval?
    }

    struct Discount {
        let periodCount: Int
        let price: Decimal
        let priceFormatted: String
    }

    enum IntroductoryOfferType: Int, Comparable {
        static let `default` = Self.none

        case trial, discount, none

        static func == (lhs: IntroductoryOfferType, rhs: IntroductoryOfferType) -> Bool {
            lhs.rawValue == rhs.rawValue
        }

        static func < (lhs: IntroductoryOfferType, rhs: IntroductoryOfferType) -> Bool {
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
        let priceFormatStyle: Decimal.FormatStyle.Currency

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

        init(id: String, type: PurchaseType, period: SubscriptionPeriod?, price: Decimal, priceFormatted: String, priceFormatStyle: Decimal.FormatStyle.Currency, introductoryOffer: Product.SubscriptionOffer?) {
            self.id = id
            self.type = type
            self.period = period
            self.price = price
            self.priceFormatted = priceFormatted
            self.priceFormatStyle = priceFormatStyle
            self.introductoryOffer = introductoryOffer
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
            price = product.price
            priceFormatted = product.displayPrice
            priceFormatStyle = product.priceFormatStyle
            introductoryOffer = product.subscription?.introductoryOffer
        }
    }

    struct PurchaseData: Codable {
        let id: String
        let type: PurchaseType
        let purchaseDate: TimeInterval
        let offerType: Int?
        let expires: ExpiresData?

        init(id: String, type: PurchaseType, purchaseDate: TimeInterval, offerType: Int?, expiresTimestamp: ExpiresData? = nil) {
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
                offerType = transaction.offer?.type.rawValue
            } else {
                offerType = transaction.offerType?.rawValue
            }

            if let expiresTimestamp = transaction.expirationDate?.timeIntervalSince1970, let period = SubscriptionPeriod(id: id) {
                expires = ExpiresData(period: period, expiresTimestamp: expiresTimestamp)
            } else {
                expires = nil
            }
        }

        init?(product: ProductData) {
            id = product.id

            guard let type = PurchaseType(id: id) else {
                return nil
            }
            self.type = type
            purchaseDate = Date().timeIntervalSince1970
            offerType = nil

            let purchaseType = PurchaseType(id: product.id) ?? .lifetime
            switch purchaseType {
            case .lifetime:
                expires = nil
            case .subscription:
                if let subscriptionPeriod = SubscriptionPeriod(id: product.id) {
                    let week = 60 * 5
                    let expireInterval: TimeInterval
                    switch subscriptionPeriod {
                    case .annually: expireInterval = Date().timeIntervalSince1970 + TimeInterval(12 * week)
                    case .monthly: expireInterval = Date().timeIntervalSince1970 + TimeInterval(week)
                    }
                    expires = ExpiresData(period: subscriptionPeriod, expiresTimestamp: expireInterval)
                } else {
                    expires = nil
                }
            }
        }
    }
}

/// test data for emulate purchases
extension PurchaseManager.ProductData {
    static var testProducts: [PurchaseManager.ProductData] {
        [
            PurchaseManager.ProductData(id: "premium_1m", type: .subscription, period: .monthly, price: 5.99, priceFormatted: "USD 5.99", priceFormatStyle: .currency(code: "USD"), introductoryOffer: nil),
            PurchaseManager.ProductData(id: "premium_1y", type: .subscription, period: .annually, price: 20.99, priceFormatted: "USD 20.99", priceFormatStyle: .currency(code: "USD"), introductoryOffer: nil),
            PurchaseManager.ProductData(id: "premium_lifetime", type: .lifetime, period: nil, price: 100, priceFormatted: "USD 100", priceFormatStyle: .currency(code: "USD"), introductoryOffer: nil),
        ]
    }
}
