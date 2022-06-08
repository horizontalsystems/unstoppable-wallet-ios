import RxSwift
import RxRelay
import RxCocoa

class SendConfirmationViewModel {
    private let disposeBag = DisposeBag()
    private let service: SendConfirmationService

    private let viewItemRelay = BehaviorRelay<[[ViewItem]]>(value: [])
    private var viewItems = [[ViewItem]]() {
        didSet {
            viewItemRelay.accept(viewItems)
        }
    }

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let sendingRelay = PublishRelay<()>()
    private let sendSuccessRelay = PublishRelay<()>()
    private let sendFailedRelay = PublishRelay<String>()

    init(service: SendConfirmationService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        syncViewItems()
    }

    private func syncViewItems() {
        var primaryViewItems = [ViewItem]()
        var secondaryViewItems = [ViewItem]()

        primaryViewItems.append(
                .subhead(
                        iconName: "arrow_medium_2_up_right_24",
                        title: "send.confirmation.you_send".localized,
                        value: service.token.coin.name
                )
        )

        service.items.forEach { item in
            switch item {
            case let item as SendConfirmationAmountViewItem:
                primaryViewItems.append(
                        .amount(
                                iconUrl: service.token.coin.imageUrl,
                                iconPlaceholderImageName: service.token.placeholderImageName,
                                coinAmount: ValueFormatter.instance.formatFull(coinValue: item.coinValue) ?? "n/a".localized,
                                currencyAmount: item.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
                                type: .neutral
                        )
                )

                primaryViewItems.append(
                        .address(
                                title: "send.confirmation.to".localized,
                                value: item.receiver.raw,
                                valueTitle: item.receiver.title
                        )
                )
            case let item as SendConfirmationMemoViewItem:
                primaryViewItems.append(
                        .value(
                                iconName: nil,
                                title: "send.confirmation.memo".localized,
                                value: item.memo,
                                type: .regular
                        )
                )
            case let item as SendConfirmationFeeViewItem:
                let value = [ValueFormatter.instance.formatFull(coinValue: item.coinValue), item.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) }]
                        .compactMap { $0 }
                        .joined(separator: " | ")

                secondaryViewItems.append(
                        .value(
                                iconName: nil,
                                title: "send.confirmation.fee".localized,
                                value: value,
                                type: .regular
                        )
                )
            case let item as SendConfirmationLockUntilViewItem:
                primaryViewItems.append(
                        .value(
                                iconName: "lock_20",
                                title: "send.confirmation.time_lock".localized,
                                value: item.lockValue,
                                type: .regular
                        )
                )

            default: ()
            }
        }

        viewItems = [primaryViewItems, secondaryViewItems]
    }

    private func sync(state: SendConfirmationService.State) {
        switch state {
        case .idle:
            sendEnabledRelay.accept(true)
        case .sending:
            sendEnabledRelay.accept(false)
            sendingRelay.accept(())
        case .sent:
            sendEnabledRelay.accept(false)
            sendSuccessRelay.accept(())
        case .failed(let error):
            sendEnabledRelay.accept(true)
            sendFailedRelay.accept(error.smartDescription)
        }
    }

}

extension SendConfirmationViewModel {

    var viewItemDriver: Driver<[[ViewItem]]> {
        viewItemRelay.asDriver()
    }

    var sendEnabledDriver: Driver<Bool> {
        sendEnabledRelay.asDriver()
    }

    var sendingSignal: Signal<()> {
        sendingRelay.asSignal()
    }

    var sendSuccessSignal: Signal<()> {
        sendSuccessRelay.asSignal()
    }

    var sendFailedSignal: Signal<String> {
        sendFailedRelay.asSignal()
    }

    func send() {
        service.send()
    }

}
extension SendConfirmationViewModel {

    enum ViewItem {
        case subhead(iconName: String, title: String, value: String)
        case amount(iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType)
        case address(title: String, value: String, valueTitle: String?)
        case value(iconName: String?, title: String, value: String, type: ValueType)
    }

}