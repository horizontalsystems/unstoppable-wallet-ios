import Combine
import Foundation
import HsExtensions

class WalletTokenBalanceViewModel {
    private var cancellables = Set<AnyCancellable>()
    private let service: WalletTokenBalanceService
    private let factory: WalletTokenBalanceViewItemFactory

    private let playHapticSubject = PassthroughSubject<Void, Never>()

    @PostPublished private(set) var viewItem: BalanceTopViewItem?

    init(service: WalletTokenBalanceService, factory: WalletTokenBalanceViewItemFactory) {
        self.service = service
        self.factory = factory

        service.$item
                .sink { [weak self] in self?.sync(item: $0) }
                .store(in: &cancellables)

        sync(item: service.item)
    }

    private func sync(item: WalletTokenBalanceService.Item?) {
        viewItem = item.map { factory.headerViewItem(item: $0) }
    }

}

extension WalletTokenBalanceViewModel {

    var playHapticPublisher: AnyPublisher<Void, Never> {
        playHapticSubject.eraseToAnyPublisher()
    }

}
