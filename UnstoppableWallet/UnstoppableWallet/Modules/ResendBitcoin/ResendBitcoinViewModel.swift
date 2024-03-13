import Combine
import Foundation
import RxCocoa
import RxSwift

class ResendBitcoinViewModel {
    private let queue = DispatchQueue(label: "\(AppConfig.label).resend_bitcoin_view_model", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private let service: ResendBitcoinService
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
    private let minFeeRelay = BehaviorRelay<Decimal?>(value: nil)

    init(service: ResendBitcoinService, contactLabelService: ContactLabelService) {
        self.service = service
        self.contactLabelService = contactLabelService

        service.$state
            .receive(on: queue)
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        service.$items
            .receive(on: queue)
            .sink { [weak self] in self?.syncViewItems(items: $0) }
            .store(in: &cancellables)

        service.$minFee
            .receive(on: queue)
            .sink { [weak self] in self?.minFeeRelay.accept(Decimal($0)) }
            .store(in: &cancellables)

        sync(state: service.state)
        syncViewItems(items: service.items)
        minFeeRelay.accept(Decimal(service.minFee))
    }

    private func syncViewItems(items: [ISendConfirmationViewItemNew]) {
        var primaryViewItems = [ViewItem]()
        var secondaryViewItems = [ViewItem]()

        primaryViewItems.append(
            .subhead(
                iconName: "arrow_medium_2_up_right_24",
                title: "send.confirmation.you_send".localized,
                value: service.token.coin.name
            )
        )

        for item in items {
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

                let contactData = contactLabelService.contactData(for: item.receiver.raw)

                primaryViewItems.append(
                    .address(
                        title: item.sentToSelf ? "send.confirmation.own".localized : "send.confirmation.to".localized,
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
                secondaryViewItems.append(
                    .fee(
                        title: "send.confirmation.fee".localized,
                        coinAmount: ValueFormatter.instance.formatFull(coinValue: item.coinValue) ?? "",
                        currencyAmount: item.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) }
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
            case let item as ReplacedTransactionHashViewItem:
                primaryViewItems.append(
                    .value(
                        iconName: nil,
                        title: "send.confirmation.replaced_transactions".localized,
                        value: "\(item.hashes.count)",
                        type: .regular
                    )
                )

            default: ()
            }
        }

        viewItems = [primaryViewItems, secondaryViewItems]
    }

    private func sync(state: ResendBitcoinService.State) {
        switch state {
        case let .unsendable(error):
            sendEnabledRelay.accept(false)
            if let error {
                sendFailedRelay.accept(error.smartDescription)
            }
        case .sendable:
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

extension ResendBitcoinViewModel {
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

    var minFeeDriver: Driver<Decimal?> {
        minFeeRelay.asDriver()
    }

    var replaceType: ResendTransactionType {
        service.type
    }

    func set(minFee: Decimal) {
        service.syncReplacement(minFee: NSDecimalNumber(decimal: minFee).intValue)
    }

    func send() {
        service.send()
    }
}

extension ResendBitcoinViewModel {
    enum ViewItem {
        case subhead(iconName: String, title: String, value: String)
        case amount(iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType)
        case address(title: String, value: String, valueTitle: String?, contactAddress: ContactAddress?)
        case value(iconName: String?, title: String, value: String, type: ValueType)
        case fee(title: String, coinAmount: String, currencyAmount: String?)
    }
}
