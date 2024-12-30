import Combine
import StoreKit

class PurchaseListViewModel: ObservableObject {
    private let purchaseManager = App.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()

    @Published var subscription: PurchaseManager.Subscription?

    init() {
        subscription = purchaseManager.subscription

        purchaseManager.$subscription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.subscription = $0 }
            .store(in: &cancellables)
    }

    func onManageSubscriptions() {
        purchaseManager.deactivate()
        subscription = nil
    }
}
