import Combine
import MarketKit
import UIKit

class RestoreSelectViewModel {
    private let service: RestoreSelectService
    private var cancellables = Set<AnyCancellable>()

    private let viewItemsSubject = CurrentValueSubject<[CoinToggleViewModel.ViewItem], Never>([])
    private let disableBlockchainSubject = PassthroughSubject<String, Never>()
    private let successSubject = PassthroughSubject<Void, Never>()

    init(service: RestoreSelectService) {
        self.service = service

        service.itemsPublisher
            .sink { [weak self] in self?.sync(items: $0) }
            .store(in: &cancellables)

        service.cancelEnableBlockchainPublisher
            .sink { [weak self] in self?.disableBlockchainSubject.send($0.uid) }
            .store(in: &cancellables)

        sync(items: service.items)
    }

    private func viewItem(item: RestoreSelectService.Item) -> CoinToggleViewModel.ViewItem {
        CoinToggleViewModel.ViewItem(
            uid: item.blockchain.uid,
            imageUrl: item.blockchain.type.imageUrl,
            placeholderImageName: "placeholder_rectangle_32",
            title: item.blockchain.name,
            subtitle: item.blockchain.type.description,
            badge: nil,
            state: .toggleVisible(enabled: item.enabled, hasSettings: item.hasSettings, hasInfo: false)
        )
    }

    private func sync(items: [RestoreSelectService.Item]) {
        viewItemsSubject.send(items.map { viewItem(item: $0) })
    }
}

extension RestoreSelectViewModel: ICoinToggleViewModel {
    var viewItemsPublisher: AnyPublisher<[CoinToggleViewModel.ViewItem], Never> {
        viewItemsSubject.eraseToAnyPublisher()
    }

    func onEnable(uid: String) {
        service.enable(blockchainUid: uid)
    }

    func onDisable(uid: String) {
        service.disable(blockchainUid: uid)
    }

    func onTapSettings(uid: String) {
        service.configure(blockchainUid: uid)
    }

    func onTapInfo(uid _: String) {}

    func onUpdate(filter _: String) {}
}

extension RestoreSelectViewModel {
    var disableBlockchainPublisher: AnyPublisher<String, Never> {
        disableBlockchainSubject.eraseToAnyPublisher()
    }

    var restoreEnabledPublisher: AnyPublisher<Bool, Never> {
        service.canRestorePublisher.eraseToAnyPublisher()
    }

    var successPublisher: AnyPublisher<Void, Never> {
        successSubject.eraseToAnyPublisher()
    }

    func onRestore() {
        service.restore()
        successSubject.send(())
    }
}
