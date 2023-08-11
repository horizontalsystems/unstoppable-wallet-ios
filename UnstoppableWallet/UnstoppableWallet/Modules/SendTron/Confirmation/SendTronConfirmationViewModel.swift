import Foundation
import RxSwift
import RxCocoa
import TronKit
import BigInt
import MarketKit
import HsExtensions

class SendTronConfirmationViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendTronConfirmationService
    private let coinServiceFactory: EvmCoinServiceFactory
    private let evmLabelManager: EvmLabelManager
    private let contactLabelService: ContactLabelService

    private let sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])

    private let sendEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let cautionsRelay = BehaviorRelay<[TitledCaution]>(value: [])

    private let sendingRelay = PublishRelay<()>()
    private let sendSuccessRelay = PublishRelay<Void>()
    private let sendFailedRelay = PublishRelay<String>()

    private let feesRelay = PublishRelay<[TronFeeViewItem]>()

    init(service: SendTronConfirmationService, coinServiceFactory: EvmCoinServiceFactory, evmLabelManager: EvmLabelManager, contactLabelService: ContactLabelService) {
        self.service = service
        self.coinServiceFactory = coinServiceFactory
        self.evmLabelManager = evmLabelManager
        self.contactLabelService = contactLabelService

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.sendStateObservable) { [weak self] in self?.sync(sendState: $0) }
        subscribe(disposeBag, service.sendAdressActiveObservable) { [weak self] _ in self?.reSyncServiceState() }
        subscribe(disposeBag, contactLabelService.stateObservable) { [weak self] _ in self?.reSyncServiceState() }

        sync(state: service.state)
        sync(sendState: service.sendState)
    }

    private func reSyncServiceState() {
        sync(state: service.state)
    }

    private func sync(state: SendTronConfirmationService.State) {
        switch state {
            case .ready(let fees):
                feesRelay.accept(feeItems(fees: fees))
                sendEnabledRelay.accept(true)
                cautionsRelay.accept([])

            case .notReady(let errors):
                feesRelay.accept([])
                sendEnabledRelay.accept(false)

                let cautions = errors.map { error in
                    if let tronError = error as? SendTronConfirmationService.TransactionError {
                        switch tronError {
                            case .insufficientBalance(let balance):
                                let coinValue = coinServiceFactory.baseCoinService.coinValue(value: balance)
                                let balanceString = ValueFormatter.instance.formatShort(coinValue: coinValue)

                                return TitledCaution(
                                    title: "fee_settings.errors.insufficient_balance".localized,
                                    text: "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? ""),
                                    type: .error
                                )

                            case .zeroAmount:
                                return TitledCaution(
                                    title: "alert.error".localized,
                                    text: "fee_settings.errors.zero_amount.info".localized,
                                    type: .error
                                )
                        }
                    } else {
                        return TitledCaution(
                            title: "Error",
                            text: error.convertedError.smartDescription,
                            type: .error
                        )
                    }
                }

                cautionsRelay.accept(cautions)
        }

        sectionViewItemsRelay.accept(items(dataState: service.dataState))
    }

    private func formatted(slippage: Decimal) -> String? {
        guard slippage != OneInchSettingsService.defaultSlippage else {
            return nil
        }

        return "\(slippage)%"
    }

    private func sync(sendState: SendTronConfirmationService.SendState) {
        switch sendState {
            case .idle: ()
            case .sending: sendingRelay.accept(())
            case .sent: sendSuccessRelay.accept(())
            case .failed(let error): sendFailedRelay.accept(error.convertedError.smartDescription)
        }
    }

    private func feeItems(fees: [Fee]) -> [TronFeeViewItem] {
        var viewItems = [TronFeeViewItem]()
        let coinService = coinServiceFactory.baseCoinService
        var bandwidth: String?
        var energy: String?

        for fee in fees {
            switch fee {
            case .accountActivation(let amount):
                let amountData = coinService.amountData(value: BigUInt(amount))

                viewItems.append(
                    TronFeeViewItem(
                        title: "tron.send.activation_fee".localized,
                        info: "tron.send.activation_fee.info".localized,
                        value1: ValueFormatter.instance.formatShort(coinValue: amountData.coinValue) ?? "n/a".localized,
                        value2: amountData.currencyValue.flatMap { ValueFormatter.instance.formatShort(currencyValue: $0) },
                        value2IsSecondary: true
                    )
                )

            case .bandwidth(let points, _):
                    bandwidth = ValueFormatter.instance.formatShort(value: Decimal(points), decimalCount: 0)

            case .energy(let required, _):
                    energy = ValueFormatter.instance.formatShort(value: Decimal(required), decimalCount: 0)
            }
        }

        if bandwidth != nil || energy != nil {
            viewItems.append(
                TronFeeViewItem(
                    title: "tron.send.resources_consumed".localized,
                    info: "tron.send.resources_consumed.info".localized,
                    value1: bandwidth.flatMap { "\($0) \("tron.send.bandwidth".localized)" } ?? "",
                    value2: energy.flatMap { "\($0) \("tron.send.energy".localized)" },
                    value2IsSecondary: false
                )
            )
        }

        return viewItems
    }

    private func items(dataState: SendTronConfirmationService.DataState) -> [SectionViewItem] {
        if let decoration = dataState.decoration, let items = self.items(decoration: decoration, contract: dataState.contract) {
            return items
        }

        return []
    }

    private func items(decoration: TransactionDecoration, contract: Contract?) -> [SectionViewItem]? {
        switch decoration {
            case let decoration as NativeTransactionDecoration:
                guard let transfer = decoration.contract as? TransferContract else {
                    return nil
                }

                return sendBaseCoinItems(
                    to: transfer.toAddress,
                    value: BigUInt(transfer.amount)
                )

            case let decoration as OutgoingEip20Decoration:
                return eip20TransferItems(
                    to: decoration.to,
                    value: decoration.value,
                    contractAddress: decoration.contractAddress
                )

            default:
                return nil
        }
    }

    private func addressActiveViewItems() -> [ViewItem] {
        guard !service.sendAdressActive else {
            return []
        }

        return [
            .warning(text: "tron.send.inactive_address".localized, title: "tron.send.activation_fee".localized, info: "tron.send.activation_fee.info".localized)
        ]
    }

    private func amountViewItem(coinService: CoinService, value: BigUInt, type: AmountType) -> ViewItem {
        amountViewItem(coinService: coinService, amountData: coinService.amountData(value: value, sign: type.sign), type: type)
    }

    private func amountViewItem(coinService: CoinService, value: Decimal, type: AmountType) -> ViewItem {
        amountViewItem(coinService: coinService, amountData: coinService.amountData(value: value, sign: type.sign), type: type)
    }

    private func amountViewItem(coinService: CoinService, amountData: AmountData, type: AmountType) -> ViewItem {
        let token = coinService.token

        return .amount(
            iconUrl: token.coin.imageUrl,
            iconPlaceholderImageName: token.placeholderImageName,
            coinAmount: ValueFormatter.instance.formatFull(coinValue: amountData.coinValue) ?? "n/a".localized,
            currencyAmount: amountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
            type: type
        )
    }

    private func estimatedAmountViewItem(coinService: CoinService, value: Decimal, type: AmountType) -> ViewItem {
        let token = coinService.token
        let amountData = coinService.amountData(value: value, sign: type.sign)
        let coinAmount = ValueFormatter.instance.formatFull(coinValue: amountData.coinValue) ?? "n/a".localized

        return .amount(
            iconUrl: token.coin.imageUrl,
            iconPlaceholderImageName: token.placeholderImageName,
            coinAmount: "\(coinAmount) \("swap.estimate_short".localized)",
            currencyAmount: amountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) },
            type: type
        )
    }

    private func sendBaseCoinItems(to: TronKit.Address, value: BigUInt) -> [SectionViewItem] {
        let toValue = to.base58
        let contactData = contactLabelService.contactData(for: toValue)

        var viewItems: [ViewItem] = [
            .subhead(
                iconName: "arrow_medium_2_up_right_24",
                title: "send.confirmation.you_send".localized,
                value: coinServiceFactory.baseCoinService.token.coin.name
            ),
            amountViewItem(
                coinService: coinServiceFactory.baseCoinService,
                value: value,
                type: .neutral
            ),
            .address(
                title: "send.confirmation.to".localized,
                value: toValue,
                valueTitle: evmLabelManager.addressLabel(address: toValue),
                contactAddress: contactData.contactAddress
            ),
        ]

        if let contactName = contactData.name {
            viewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
        }

        return [SectionViewItem(viewItems: viewItems + addressActiveViewItems())]
    }

    private func eip20TransferItems(to: TronKit.Address, value: BigUInt, contractAddress: TronKit.Address) -> [SectionViewItem]? {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return nil
        }

        var viewItems: [ViewItem] = [
            .subhead(
                iconName: "arrow_medium_2_up_right_24",
                title: "send.confirmation.you_send".localized,
                value: coinService.token.coin.name
            ),
            amountViewItem(
                coinService: coinService,
                value: value,
                type: .neutral
            )
        ]

        let addressValue = to.base58
        let addressTitle = evmLabelManager.addressLabel(address: addressValue)

        let contactData = contactLabelService.contactData(for: addressValue)

        viewItems.append(.address(
            title: "send.confirmation.to".localized,
            value: addressValue,
            valueTitle: addressTitle,
            contactAddress: contactData.contactAddress
        )
        )
        if let contactName = contactData.name {
            viewItems.append(.value(title: "send.confirmation.contact_name".localized, value: contactName, type: .regular))
        }

        return [SectionViewItem(viewItems: viewItems + addressActiveViewItems())]
    }

    private func coinService(token: MarketKit.Token) -> CoinService {
        coinServiceFactory.coinService(token: token)
    }

}

extension SendTronConfirmationViewModel {

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    var feesSignal: Signal<[TronFeeViewItem]> {
        feesRelay.asSignal()
    }

    var sendEnabledDriver: Driver<Bool> {
        sendEnabledRelay.asDriver()
    }

    var cautionsDriver: Driver<[TitledCaution]> {
        cautionsRelay.asDriver()
    }

    var sendingSignal: Signal<()> {
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

extension SendTronConfirmationViewModel {

    struct SectionViewItem {
        let viewItems: [ViewItem]
    }

    enum ViewItem {
        case subhead(iconName: String, title: String, value: String)
        case amount(iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType)
        case address(title: String, value: String, valueTitle: String?, contactAddress: ContactAddress?)
        case value(title: String, value: String, type: ValueType)
        case warning(text: String, title: String, info: String)
    }

    struct TronFeeViewItem {
        let title: String
        let info: String
        let value1: String
        let value2: String?
        let value2IsSecondary: Bool
    }

}
