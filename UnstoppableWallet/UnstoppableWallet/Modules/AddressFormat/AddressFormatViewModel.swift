import RxSwift
import RxRelay
import RxCocoa

class AddressFormatViewModel {
    private let service: AddressFormatService
    private let disposeBag = DisposeBag()

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])
    private let showConfirmationRelay = PublishRelay<(coinTypeTitle: String, settingName: String)>()

    private var currentIndices: (sectionIndex: Int, index: Int)?

    init(service: AddressFormatService) {
        self.service = service

        service.itemsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] items in
                    self?.sync(items: items)
                })
                .disposed(by: disposeBag)

        sync(items: service.items)
    }

    private func sync(items: [AddressFormatService.Item]) {
        let sectionViewItems = items.map { item in
            SectionViewItem(
                    coinTypeName: "\(item.coinType.title)",
                    viewItems: viewItems(itemType: item.type, coinType: item.coinType)
            )
        }

        sectionViewItemsRelay.accept(sectionViewItems)
    }

    private func viewItems(itemType: AddressFormatService.ItemType, coinType: CoinType) -> [ViewItem] {
        switch itemType {
        case .derivation(let derivations, let current):
            return derivations.map { derivation in
                ViewItem(title: derivation.title, subtitle: derivation.description(coinType: coinType), selected: derivation == current)
            }
        case .bitcoinCashCoinType(let types, let current):
            return types.map { type in
                ViewItem(title: type.title, subtitle: type.description, selected: type == current)
            }
        }
    }

}

extension AddressFormatViewModel {

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    var showConfirmationSignal: Signal<(coinTypeTitle: String, settingName: String)> {
        showConfirmationRelay.asSignal()
    }

    func onSelect(sectionIndex: Int, index: Int) {
        let item = service.items[sectionIndex]
        currentIndices = (sectionIndex: sectionIndex, index: index)

        switch item.type {
        case .derivation(let derivations, let current):
            let selectedDerivation = derivations[index]

            guard selectedDerivation != current else {
                return
            }

            showConfirmationRelay.accept((coinTypeTitle: item.coinType.title, settingName: selectedDerivation.rawValue.uppercased()))

        case .bitcoinCashCoinType(let types, let current):
            let selectedType = types[index]

            guard selectedType != current else {
                return
            }

            showConfirmationRelay.accept((coinTypeTitle: item.coinType.title, settingName: selectedType.title))
        }
    }

    func onConfirm() {
        guard let (sectionIndex, index) = currentIndices else {
            return
        }

        let item = service.items[sectionIndex]

        switch item.type {
        case .derivation(let derivations, _):
            service.set(derivation: derivations[index], coinType: item.coinType)
        case .bitcoinCashCoinType(let types, _):
            service.set(bitcoinCashCoinType: types[index])
        }
    }

}

extension AddressFormatViewModel {

    struct SectionViewItem {
        let coinTypeName: String
        let viewItems: [ViewItem]
    }

    struct ViewItem {
        let title: String
        let subtitle: String
        let selected: Bool
    }

}
