import Combine
import Foundation
import StoreKit

@MainActor
class PurchaseBottomSheetViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private var waitTask: Task<Void, Never>?

    @Published var items: [PurchaseProductItemFactory.Item] = []
    @Published var selectedItem: PurchaseProductItemFactory.Item?

    @Published var buttonState: ButtonState = .idle

    private let purchaseManager = Core.shared.purchaseManager

    private let finishSubject = PassthroughSubject<Void, Never>()
    private let onSubscribe: @MainActor (PurchaseManager.ProductData) -> Void

    private var monthlyPrice: Decimal? {
        purchaseManager.productData.first { $0.type == .subscription && $0.period == .monthly }?.price
    }

    init(onSubscribe: @escaping @MainActor (PurchaseManager.ProductData) -> Void) {
        self.onSubscribe = onSubscribe

        updateItems(data: purchaseManager.productData)

        purchaseManager.purchaseDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(purchases: $0)
            }
            .store(in: &cancellables)

        purchaseManager.productDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.updateItems(data: products)
            }
            .store(in: &cancellables)

        purchaseManager.usedOfferProductIdsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateItems(data: self?.purchaseManager.productData ?? [])
            }
            .store(in: &cancellables)
    }

    private func updateItems(data: [PurchaseManager.ProductData]) {
//        print(data)
        items = data
            .sorted { $0.order < $1.order }
            .compactMap {
                let used = purchaseManager.usedOfferProductIds.contains($0.id)
                return PremiumFactory.productItemFactory.item(product: $0, offerWasUsed: used, monthlyPrice: monthlyPrice)
            }

        selectedItem = items.first { $0 == selectedItem } ?? items.first
    }

    private func waitTransaction() {
        waitTask?.cancel()
        buttonState = .loading

        waitTask = Task { [weak self] in
            do {
                try await Task.sleep(seconds: 5)
            } catch {
                // cancelled: the purchase arrived, or a newer wait took over
                return
            }

            self?.buttonState = .idle
        }
    }

    private func handleSuccessSubscription(_ product: PurchaseManager.ProductData) {
        onSubscribe(product)
        finishSubject.send()
    }

    private func handle(purchases _: [PurchaseManager.PurchaseData]) {
        if let purchase = purchaseManager.activePurchase, let product = purchaseManager.productData.first(where: { $0.id == purchase.id }) {
            waitTask?.cancel()
            waitTask = nil

            handleSuccessSubscription(product)
        }
    }

    func subscribe() {
        // Checked and set synchronously, so a second tap cannot start a second purchase
        guard buttonState != .loading, let product = selectedItem?.product else {
            return
        }

        buttonState = .loading

        Task { [weak self] in
            do {
                let outcome = try await self?.purchaseManager.purchase(product: product)

                self?.buttonState = .idle

                // a pending purchase reaches success later, through the `purchaseData` sink, once it is approved
                if outcome == .purchased {
                    self?.handleSuccessSubscription(product)
                }
            } catch {
                self?.buttonState = .idle

                if !Self.isCancellation(error) {
                    HudHelper.instance.show(banner: .error(string: Self.message(for: error)))
                }
            }
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if case PurchaseManager.SubscribeError.userCancelled = error {
            return true
        }

        if case StoreKitError.userCancelled = error {
            return true
        }

        return false
    }

    private static func message(for error: Error) -> String {
        error is LocalizedError ? error.localizedDescription : "alert.unknown_error".localized
    }
}

extension PurchaseBottomSheetViewModel {
    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    func handleRedeemCode(result: Result<Void, any Error>) {
        switch result {
        case .success(): // wait transaction and handle it
            waitTransaction()
        case let .failure(error): // don't doing anything
            print(error)
        }
    }
}

extension PurchaseBottomSheetViewModel {
    enum ButtonState {
        case idle
        case loading
    }
}

extension PurchaseManager.SubscriptionPeriod: Identifiable {
    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .annually: return "purchase.period.annually".localized
        case .monthly: return "purchase.period.monthly".localized
        }
    }

    var pricePeriod: String {
        switch self {
        case .annually: return "purchase.period.year".localized
        case .monthly: return "purchase.period.month".localized
        }
    }
}

extension PurchaseManager.ProductData {
    var order: Int {
        switch type {
        case .lifetime: return 2
        case .subscription:
            switch period {
            case .monthly: return 1
            case .annually: return 0
            case .none: return 3
            }
        }
    }
}
