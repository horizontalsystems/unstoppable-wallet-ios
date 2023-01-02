import RxSwift
import RxRelay
import RxCocoa

class BtcBlockchainSettingsViewModel {
    private let service: BtcBlockchainSettingsService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(addressFormatViewItems: nil, restoreSourceViewItems: nil, applyEnabled: false))
    private let approveApplyRelay = PublishRelay<()>()
    private let approveRelay = PublishRelay<[CoinSettings]>()
    private let finishRelay = PublishRelay<()>()

    init(service: BtcBlockchainSettingsService) {
        self.service = service

        subscribe(disposeBag, service.itemObservable) { [weak self] in self?.sync(item: $0) }

        sync(item: service.item)
    }

    private func sync(item: BtcBlockchainSettingsService.Item) {
        var addressFormatViewItems: [RowViewItem]?

        if !service.addressFormatHidden {
            switch item.addressFormat {
            case let .derivation(items):
                addressFormatViewItems = items.map { item in
                    RowViewItem(
                            title: item.derivation.title,
                            subtitle: item.derivation.description,
                            selected: item.selected
                    )
                }
            case let .bitcoinCashCoinType(items):
                addressFormatViewItems = items.map { item in
                    RowViewItem(
                            title: item.bitcoinCashCoinType.title,
                            subtitle: item.bitcoinCashCoinType.description,
                            selected: item.selected
                    )
                }
            default: ()
            }
        }

        var restoreSourceViewItems: [RowViewItem]?

        if let restoreSource = item.restoreSource {
            restoreSourceViewItems = RestoreSource.allCases.map {
                RowViewItem(
                        title: $0.title,
                        subtitle: $0.description,
                        selected: $0 == restoreSource
                )
            }
        }

        let viewItem = ViewItem(
                addressFormatViewItems: addressFormatViewItems,
                restoreSourceViewItems: restoreSourceViewItems,
                applyEnabled: item.applyEnabled
        )

        viewItemRelay.accept(viewItem)
    }

    private func apply() {
        if service.autoSave {
            service.saveSettings()
            finishRelay.accept(())
        } else {
            approveRelay.accept(service.resolveCoinSettingsArray())
        }
    }

}

extension BtcBlockchainSettingsViewModel {

    var viewItemDriver: Driver<ViewItem> {
        viewItemRelay.asDriver()
    }

    var approveApplySignal: Signal<()> {
        approveApplyRelay.asSignal()
    }

    var approveSignal: Signal<[CoinSettings]> {
        approveRelay.asSignal()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var blockchainIconUrl: String {
        service.blockchain.type.imageUrl
    }

    var blockchainName: String {
        service.blockchain.name
    }

    func onToggleAddressFormat(index: Int, selected: Bool) {
        service.toggleAddressFormat(index: index, selected: selected)
    }

    func onSelectRestoreSource(index: Int) {
        let restoreSource = RestoreSource.allCases[index]
        service.set(restoreSource: restoreSource)
    }

    func onTapApply() {
        if service.approveApplyRequired {
            approveApplyRelay.accept(())
        } else {
            apply()
        }
    }

    func onApproveApply() {
        apply()
    }

}

extension BtcBlockchainSettingsViewModel {

    struct ViewItem {
        let addressFormatViewItems: [RowViewItem]?
        let restoreSourceViewItems: [RowViewItem]?
        let applyEnabled: Bool
    }

    struct RowViewItem {
        let title: String
        let subtitle: String
        let selected: Bool
    }

}
