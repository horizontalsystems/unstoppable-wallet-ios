import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class SendConfirmationViewModel {
    private let disposeBag = DisposeBag()
    private let service: SendConfirmationService
    private let contactLabelService: ContactLabelService

    private let viewItemRelay = BehaviorRelay<[[ViewItem]]>(value: [])
    private var viewItems = [[ViewItem]]() {
        didSet {
            viewItemRelay.accept(viewItems)
        }
    }

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let sendingRelay = PublishRelay<Void>()
    private let sendSuccessRelay = PublishRelay<Void>()
    private let sendFailedRelay = PublishRelay<String>()

    init(service: SendConfirmationService, contactLabelService: ContactLabelService) {
        self.service = service
        self.contactLabelService = contactLabelService

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, contactLabelService.stateObservable) { [weak self] _ in
            self?.syncViewItems()
        }

        syncViewItems()
    }

    private func syncViewItems() {
        var primaryViewItems = [ViewItem]()
        var secondaryViewItems = [ViewItem]()

        for item in service.items {
            switch item {
            case let item as SendConfirmationAmountViewItem:
                primaryViewItems.append(
                    .amount(
                        title: "send.confirmation.you_send".localized,
                        token: service.token,
                        coinAmount: ValueFormatter.instance.formatFull(coinValue: item.coinValue) ?? "n/a".localized,
                        currencyAmount: item.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
                        type: .neutral
                    )
                )

                let contactData = contactLabelService.contactData(for: item.receiver.raw)

                primaryViewItems.append(
                    .address(
                        title: "send.confirmation.to".localized,
                        value: item.receiver.raw,
                        valueTitle: item.receiver.title,
                        contactAddress: contactData.contactAddress
                    )
                )
                if let contactName = contactData.name {
                    primaryViewItems.append(
                        .value(
                            iconName: nil,
                            title: "send.confirmation.contact_name".localized,
                            value: contactName,
                            type: .regular
                        )
                    )
                }
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
                        iconName: "lock_24",
                        title: "send.confirmation.time_lock".localized,
                        value: item.lockValue,
                        type: .regular
                    )
                )
            case _ as SendConfirmationDisabledRbfViewItem:
                primaryViewItems.append(
                    .value(
                        iconName: nil,
                        title: "send.confirmation.replace_by_fee".localized,
                        value: "send.confirmation.replace_by_fee.disabled".localized,
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
        case let .failed(error):
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

    var sendingSignal: Signal<Void> {
        sendingRelay.asSignal()
    }

    var sendSuccessSignal: Signal<Void> {
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
        case amount(title: String, token: Token, coinAmount: String, currencyAmount: String?, type: AmountType)
        case address(title: String, value: String, valueTitle: String?, contactAddress: ContactAddress?)
        case value(iconName: String?, title: String, value: String, type: ValueType)
    }
}
