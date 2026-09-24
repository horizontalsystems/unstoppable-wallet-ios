import Combine
import Foundation
import MarketKit

// The chain-agnostic form state shared by the Standard and Private tabs of PreSendView: amount/fiat
// input, recipient address, balance and adapter state. Subclasses decide how `sendData` is built.
public class BasePreSendViewModel: ObservableObject {
    let wallet: Wallet
    let handler: IPreSendHandler?
    private let customDecimals: Int?

    private let currencyManager = Core.shared.currencyManager
    private let marketKit = Core.shared.marketKit
    private let contactManager = Core.shared.contactManager

    var cancellables = Set<AnyCancellable>()

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

    init(wallet: Wallet, handler: IPreSendHandler?, predefinedAddress: ResolvedAddress?, amount: Decimal?, customDecimals: Int? = nil) {
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

        coinPrice = marketKit.coinPrice(coinUid: wallet.coin.uid, currencyCode: currency.code)
        marketKit.coinPricePublisher(coinUid: wallet.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in self?.coinPrice = price }
            .store(in: &cancellables)

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

    func setAmountIn(percent: Int) {
        guard let availableBalance else {
            return
        }

        enteringFiat = false

        amount = (availableBalance * Decimal(percent) / 100).roundedDown(decimal: customDecimals ?? token.decimals)
    }

    func clearAmountIn() {
        enteringFiat = false
        amountString = ""
    }

    private func syncAmount() {
        guard enteringFiat else {
            return
        }

        guard let coinPrice, let fiatAmount else {
            amount = nil
            return
        }

        amount = (fiatAmount / coinPrice.value).roundedDown(decimal: customDecimals ?? token.decimals)
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
        contactName = resolvedAddress.flatMap { contactManager.name(blockchainType: token.blockchainType, address: $0.address) }
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
