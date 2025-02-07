import Combine
import Foundation

class PurchaseBottomSheetViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published var items: [Item] = []
    @Published var selectedItem: Item?

    @Published var allowTrialPeriod: Bool = false
    @Published var buttonState: ButtonState = .idle

    private let purchaseManager = App.shared.purchaseManager

    private let onSubscribe: (PurchaseManager.ProductData) -> Void

    private var monthlyPrice: Decimal? {
        purchaseManager.productData.first { $0.type == .subscription && $0.period == .monthly }?.price
    }

    init(onSubscribe: @escaping ((PurchaseManager.ProductData) -> Void)) {
        self.onSubscribe = onSubscribe

        updateItems(data: purchaseManager.productData)

        allowTrialPeriod = purchaseManager.purchaseData.isEmpty

        purchaseManager.$purchaseData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] purchases in
                self?.allowTrialPeriod = !purchases.isEmpty
            }
            .store(in: &cancellables)

        purchaseManager.$productData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.updateItems(data: products)
            }
            .store(in: &cancellables)
    }

    private func updateItems(data: [PurchaseManager.ProductData]) {
        print(data)
        items = data
            .sorted { $0.order < $1.order }
            .compactMap { Item(product: $0, monthlyPrice: monthlyPrice) }

        selectedItem = selectedItem ?? items.first
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
                guard let selectedItem else {
                    return
                }

                try await purchaseManager.purchase(product: selectedItem.product)

                await update(state: .idle)

                onSubscribe(selectedItem.product)
            } catch {
                print("ERROR: \(error)") // TODO: Handle error
                await update(state: .idle)
            }
        }
    }
}

extension PurchaseBottomSheetViewModel {
    func set(item: Item) {
        selectedItem = item
    }
}

extension PurchaseBottomSheetViewModel {
    enum ButtonState {
        case idle
        case loading
    }

    struct Item: Hashable, Equatable {
        let product: PurchaseManager.ProductData
        let title: String
        let discountBadge: String?

        let price: String
        let priceDescription: String?
        let priceDescripionAccented: Bool

        let hasTrialPeriod: Bool

        init?(product: PurchaseManager.ProductData, monthlyPrice: Decimal?) {
            self.product = product
            price = product.priceFormatted
            hasTrialPeriod = product.hasTrialPeriod

            switch product.type {
            case .lifetime:
                title = "purchase.period.onetime".localized
                discountBadge = nil

                priceDescription = nil
                priceDescripionAccented = false
            case .subscription:
                guard let period = product.period else {
                    return nil
                }

                title = period.title
                switch period {
                case .monthly:
                    discountBadge = nil

                    priceDescription = nil
                    priceDescripionAccented = false
                case .annually:
                    let realMonthlyPrice = product.price / 12

                    if let monthlyPrice, monthlyPrice > 0 {
                        let discountPrecentage = ((monthlyPrice - realMonthlyPrice) / monthlyPrice) * 100
                        discountBadge = ["purchase.period.save".localized.uppercased(), "\(discountPrecentage.rounded(decimal: 0))%"].joined(separator: " ")

                        priceDescription = "(\([realMonthlyPrice.rounded(decimal: 2).description, period.pricePeriod].joined(separator: "/")))"
                        priceDescripionAccented = true
                    } else {
                        discountBadge = nil
                        priceDescription = nil
                        priceDescripionAccented = false
                    }
                }
            }
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(product.id)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.product.id == rhs.product.id
        }
    }
}

extension PurchaseManager.SubscriptionPeriod: Identifiable {
    var id: String { rawValue }

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
