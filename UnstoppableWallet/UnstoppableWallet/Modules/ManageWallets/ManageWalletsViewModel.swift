import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class ManageWalletsViewModel {
    private let service: ManageWalletsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let notFoundVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let disableItemRelay = PublishRelay<Int>()
    private let showBirthdayHeightRelay = PublishRelay<BirthdayHeightViewItem>()

    init(service: ManageWalletsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.cancelEnableObservable) { [weak self] in self?.disableItemRelay.accept($0) }

        sync(items: service.items)
    }

    private func viewItem(item: ManageWalletsService.Item) -> ViewItem {
        let token = item.configuredToken.token

        return ViewItem(
                uid: String(item.configuredToken.hashValue),
                imageUrl: token.coin.imageUrl,
                placeholderImageName: token.placeholderImageName,
                title: token.coin.code,
                subtitle: token.coin.name,
                badge: item.configuredToken.badge,
                enabled: item.enabled,
                hasInfo: item.hasInfo
        )
    }

    private func sync(items: [ManageWalletsService.Item]) {
        viewItemsRelay.accept(items.map { viewItem(item: $0) })
        notFoundVisibleRelay.accept(items.isEmpty)
    }

}

extension ManageWalletsViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var notFoundVisibleDriver: Driver<Bool> {
        notFoundVisibleRelay.asDriver()
    }

    var disableItemSignal: Signal<Int> {
        disableItemRelay.asSignal()
    }

    var showBirthdayHeightSignal: Signal<BirthdayHeightViewItem> {
        showBirthdayHeightRelay.asSignal()
    }

    var addTokenEnabled: Bool {
        service.accountType.canAddTokens
    }

    func onEnable(index: Int) {
        service.enable(index: index)
    }

    func onDisable(index: Int) {
        service.disable(index: index)
    }

    func onTapInfo(index: Int) {
        guard let (blockchain, birthdayHeight) = service.birthdayHeight(index: index) else {
            return
        }

        let viewItem = BirthdayHeightViewItem(
                blockchainImageUrl: blockchain.type.imageUrl,
                blockchainName: blockchain.name,
                birthdayHeight: String(birthdayHeight)
        )

        showBirthdayHeightRelay.accept(viewItem)
    }

    func onUpdate(filter: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter)
        }
    }

}

extension ManageWalletsViewModel {

    struct ViewItem {
        let uid: String
        let imageUrl: String
        let placeholderImageName: String?
        let title: String
        let subtitle: String
        let badge: String?
        let enabled: Bool
        let hasInfo: Bool
    }

    struct BirthdayHeightViewItem {
        let blockchainImageUrl: String
        let blockchainName: String
        let birthdayHeight: String
    }

}
