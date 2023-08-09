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
    private let showInfoRelay = PublishRelay<InfoViewItem>()
    private let showBirthdayHeightRelay = PublishRelay<BirthdayHeightViewItem>()
    private let showContractRelay = PublishRelay<ContractViewItem>()

    init(service: ManageWalletsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, service.cancelEnableObservable) { [weak self] in self?.disableItemRelay.accept($0) }

        sync(items: service.items)
    }

    private func viewItem(item: ManageWalletsService.Item) -> ViewItem {
        let token = item.token

        return ViewItem(
                uid: String(item.token.hashValue),
                imageUrl: token.coin.imageUrl,
                placeholderImageName: token.placeholderImageName,
                title: token.coin.code,
                subtitle: token.coin.name,
                badge: item.token.badge,
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

    var showInfoSignal: Signal<InfoViewItem> {
        showInfoRelay.asSignal()
    }

    var showBirthdayHeightSignal: Signal<BirthdayHeightViewItem> {
        showBirthdayHeightRelay.asSignal()
    }

    var showContractSignal: Signal<ContractViewItem> {
        showContractRelay.asSignal()
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
        guard let infoItem = service.infoItem(index: index) else {
            return
        }

        let coinViewItem = CoinViewItem(
                coinImageUrl: infoItem.token.coin.imageUrl,
                coinPlaceholderImageName: infoItem.token.placeholderImageName,
                coinName: infoItem.token.coin.name,
                coinCode: infoItem.token.coin.code
        )


        switch infoItem.type {
        case .derivation:
            let coinName = infoItem.token.coin.name
            showInfoRelay.accept(InfoViewItem(coin: coinViewItem, text: "manage_wallets.derivation_description".localized(coinName, AppConfig.appName, coinName)))
        case .bitcoinCashCoinType:
            showInfoRelay.accept(InfoViewItem(coin: coinViewItem, text: "manage_wallets.bitcoin_cash_coin_type_description".localized(AppConfig.appName)))
        case .birthdayHeight(let height):
            showBirthdayHeightRelay.accept(BirthdayHeightViewItem(coin: coinViewItem, height: String(height)))
        case let .contractAddress(value, explorerUrl):
            showContractRelay.accept(ContractViewItem(coin: coinViewItem, blockchainImageUrl: infoItem.token.blockchainType.imageUrl, value: value, explorerUrl: explorerUrl))
        }
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

    struct CoinViewItem {
        let coinImageUrl: String
        let coinPlaceholderImageName: String
        let coinName: String
        let coinCode: String
    }

    struct InfoViewItem {
        let coin: CoinViewItem
        let text: String
    }

    struct BirthdayHeightViewItem {
        let coin: CoinViewItem
        let height: String
    }

    struct ContractViewItem {
        let coin: CoinViewItem
        let blockchainImageUrl: String
        let value: String
        let explorerUrl: String?
    }

}
