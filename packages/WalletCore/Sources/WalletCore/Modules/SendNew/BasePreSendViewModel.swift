import Combine
import Foundation
import MarketKit

// The chain-agnostic form state shared by the Standard, Private and Cross Pay tabs of PreSendView:
// amount/fiat input, recipient address, balance and adapter state. Subclasses decide how `sendData` is
// built, and may denominate the amount and the recipient in a token other than the wallet's.
public class BasePreSendViewModel: ObservableObject {
    let wallet: Wallet
    let handler: IPreSendHandler?
    private let customDecimals: Int?

    private let currencyManager = Core.shared.currencyManager
    private let marketKit = Core.shared.marketKit
    private let contactManager = Core.shared.contactManager

    var cancellables = Set<AnyCancellable>()
    private var coinPriceCancellable: AnyCancellable?

    @Published var currency: Currency

    public var amount: Decimal? {
        didSet {
            syncFiatAmount()
            syncSendData()

            var amount = AmountDecimalParser.parseAnyDecimal(from: amountString)

            if amount == 0 {
                amount = nil
            }

            if amount != self.amount {
                amountString = AmountDecimalParser.string(from: self.amount)
            }
        }
    }

    @Published public var amountString: String = "" {
        didSet {
            var amount = AmountDecimalParser.parseAnyDecimal(from: amountString)

            if amount == 0 {
                amount = nil
            }

            amount = roundedInput(amount)

            guard amount != self.amount else {
                return
            }

            enteringFiat = false

            self.amount = amount
        }
    }

    @Published var fiatAmount: Decimal? {
        didSet {
            syncAmount()

            let amount = AmountDecimalParser.parseAnyDecimal(from: fiatAmountString)?.rounded(decimal: 2)

            if amount != fiatAmount {
                fiatAmountString = AmountDecimalParser.string(from: fiatAmount)
            }
        }
    }

    @Published var fiatAmountString: String = "" {
        didSet {
            let amount = AmountDecimalParser.parseAnyDecimal(from: fiatAmountString)?.rounded(decimal: 2)

            guard amount != fiatAmount else {
                return
            }

            enteringFiat = true

            fiatAmount = amount
        }
    }

    @Published var coinPrice: CoinPrice? {
        didSet {
            syncFiatAmount()
        }
    }

    @Published public private(set) var adapterState: AdapterState?
    @Published public private(set) var availableBalance: Decimal?

    private var enteringFiat = false

    @Published private(set) var resolvedAddress: ResolvedAddress?
    @Published private(set) var contactName: String?
    @Published public internal(set) var sendData: ExtendedSendData?
    @Published public var cautions = [CautionNew]()

    // `initialInputToken` is the token `inputToken` resolves to at construction time; the coin price is
    // subscribed for it up front. Nil means no token is chosen yet, so no price is subscribed.
    init(wallet: Wallet, handler: IPreSendHandler?, predefinedAddress: ResolvedAddress?, amount: Decimal?, initialInputToken: Token?, customDecimals: Int? = nil) {
        self.wallet = wallet
        self.handler = handler
        resolvedAddress = predefinedAddress
        self.customDecimals = customDecimals

        currency = currencyManager.baseCurrency

        defer {
            if let amount {
                self.amount = amount
            }
        }

        currencyManager.$baseCurrency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.currency = $0 }
            .store(in: &cancellables)

        // Not `inputToken`: an overridable member must not be read before the subclass is initialized.
        subscribeCoinPrice(token: initialInputToken)

        if let handler {
            adapterState = handler.state
            availableBalance = handler.balance

            handler.statePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.adapterState = $0 }
                .store(in: &cancellables)

            handler.balancePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.availableBalance = $0 }
                .store(in: &cancellables)

            handler.settingsModifiedPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.syncSendData() }
                .store(in: &cancellables)
        }

        syncContactName()
        syncFiatAmount()
    }

    func set(address: ResolvedAddress?) {
        guard address != resolvedAddress else {
            return
        }

        resolvedAddress = address
        syncContactName()
        didChangeAddress()
        syncSendData()
    }

    // Hook for subclasses, called after the address changes and before `syncSendData()`.
    func didChangeAddress() {}

    func syncSendData() {
        sendData = nil
    }

    // The token the amount/fiat input is denominated in. Nil means no token is chosen yet.
    var inputToken: Token? {
        token
    }

    // The token whose chain the recipient address belongs to. Nil means no token is chosen yet.
    var addressToken: Token? {
        token
    }

    // The source address for the address picker's self-send check.
    var addressFromAddress: String? {
        Core.shared.adapterManager.depositAdapter(for: wallet)?.receiveAddress.address
    }

    var balancePercents: [Int] {
        [25, 50, 75]
    }

    var maxAmountEnabled: Bool {
        true
    }

    // Applied to the typed amount before it is compared with and assigned to `amount`.
    func roundedInput(_ amount: Decimal?) -> Decimal? {
        amount
    }

    // Whether the fiat input may be converted to an amount with this price.
    func canConvertFiat(coinPrice _: CoinPrice) -> Bool {
        true
    }

    var buttonState: PreSendButtonState {
        let title: String
        var disabled = true
        var showProgress = false

        if adapterState == nil {
            title = "send.token_not_enabled".localized
        } else if let adapterState, adapterState.syncing {
            title = "send.token_syncing".localized
            showProgress = true
        } else if let adapterState, !adapterState.isSynced {
            title = "send.token_not_synced".localized
        } else if amount == nil {
            title = "send.enter_amount".localized
        } else if let availableBalance, let amount, amount > availableBalance {
            title = "send.insufficient_balance".localized
        } else if resolvedAddress == nil {
            title = "send.address.enter_address".localized
        } else {
            title = "send.next_button".localized
            disabled = sendData == nil
        }

        return PreSendButtonState(title: title, disabled: disabled, showProgress: showProgress)
    }

    func subscribeCoinPrice(token: Token?) {
        coinPriceCancellable = nil

        guard let token else {
            coinPrice = nil
            return
        }

        coinPrice = marketKit.coinPrice(coinUid: token.coin.uid, currencyCode: currency.code)
        coinPriceCancellable = marketKit.coinPricePublisher(coinUid: token.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in self?.coinPrice = price }
    }

    func setAmountIn(percent: Int) {
        if !maxAmountEnabled, percent == 100 {
            return
        }

        if percent != 100, !balancePercents.contains(percent) {
            return
        }

        guard let availableBalance else {
            return
        }

        enteringFiat = false

        let amount = availableBalance * Decimal(percent) / 100

        if let decimals = customDecimals ?? inputToken?.decimals {
            self.amount = amount.roundedDown(decimal: decimals)
        } else {
            self.amount = amount
        }
    }

    func clearAmountIn() {
        enteringFiat = false
        amountString = ""
    }

    private func syncAmount() {
        guard enteringFiat else {
            return
        }

        guard let coinPrice, canConvertFiat(coinPrice: coinPrice), let fiatAmount else {
            amount = nil
            return
        }

        let amount = fiatAmount / coinPrice.value

        if let decimals = customDecimals ?? inputToken?.decimals {
            self.amount = amount.roundedDown(decimal: decimals)
        } else {
            self.amount = amount
        }
    }

    private func syncFiatAmount() {
        guard !enteringFiat else {
            return
        }

        guard let coinPrice, let amount else {
            fiatAmount = nil
            return
        }

        fiatAmount = (amount * coinPrice.value).rounded(decimal: 2)
    }

    private func syncContactName() {
        guard let addressToken else {
            contactName = nil
            return
        }

        contactName = resolvedAddress.flatMap { contactManager.name(blockchainType: addressToken.blockchainType, address: $0.address) }
    }
}

public extension BasePreSendViewModel {
    var token: Token {
        wallet.token
    }
}

public extension BasePreSendViewModel {
    struct ExtendedSendData {
        public let sendData: SendData
        public let address: String?
    }
}

struct PreSendButtonState {
    let title: String
    let disabled: Bool
    let showProgress: Bool
}
