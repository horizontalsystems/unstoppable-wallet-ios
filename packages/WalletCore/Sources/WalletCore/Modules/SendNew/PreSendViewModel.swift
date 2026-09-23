import Combine
import Foundation
import MarketKit

public class PreSendViewModel: ObservableObject {
    let wallet: Wallet
    private let currencyManager = Core.shared.currencyManager
    private let marketKit = Core.shared.marketKit
    private let walletManager = Core.shared.walletManager
    private let adapterManager = Core.shared.adapterManager
    private let contactManager = Core.shared.contactManager

    private var cancellables = Set<AnyCancellable>()

    @Published var currency: Currency
    private let customDecimals: Int?

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
    @Published var memoType: MemoType = .none
    @Published var destinationTagState: DestinationTagState = .hidden

    private var enteringFiat = false

    @Published var memo: String = "" {
        didSet {
            syncSendData()
        }
    }

    @Published var destinationTag: String = "" {
        didSet {
            syncSendData()
        }
    }

    var handler: IPreSendHandler?
    @Published private(set) var resolvedAddress: ResolvedAddress?
    @Published private(set) var contactName: String?
    @Published public private(set) var sendData: ExtendedSendData?
    @Published public var cautions = [CautionNew]()

    public init(wallet: Wallet, predefinedAddress: ResolvedAddress?, amount: Decimal?, memo: String?, customDecimals: Int? = nil) {
        self.wallet = wallet
        handler = SendHandlerFactory.preSendHandler(wallet: wallet, address: predefinedAddress)
        resolvedAddress = predefinedAddress
        self.customDecimals = customDecimals

        currency = currencyManager.baseCurrency

        defer {
            if let amount {
                self.amount = amount
            }
            if let memo {
                self.memo = memo
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
            destinationTagState = handler.destinationTagState

            handler.destinationTagStatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.destinationTagState = $0
                    self?.syncSendData()
                }
                .store(in: &cancellables)

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

        syncMemoType()
        syncContactName()
        syncFiatAmount()
    }

    func set(address: ResolvedAddress?) {
        guard address != resolvedAddress else {
            return
        }

        resolvedAddress = address
        handler?.set(address: address?.address)
        syncMemoType()
        syncContactName()
        syncSendData()
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

    private func syncMemoType() {
        guard let handler else {
            memoType = .none
            return
        }

        memoType = handler.memoType(address: resolvedAddress?.address)
    }

    private func syncContactName() {
        contactName = resolvedAddress.flatMap { contactManager.name(blockchainType: token.blockchainType, address: $0.address) }
    }
}

public extension PreSendViewModel {
    var token: Token {
        wallet.token
    }

    internal var title: String {
        handler?.title(token.coin.code) ?? "send.send".localized
    }

    internal func syncSendData() {
        guard let amount else {
            sendData = nil
            return
        }

        guard let resolvedAddress else {
            sendData = nil
            cautions = []
            return
        }

        guard let handler else {
            sendData = nil
            return
        }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespaces)
        let memo = memoType != .none && !trimmedMemo.isEmpty ? trimmedMemo : nil

        let result = handler.sendData(amount: amount, address: resolvedAddress.address, memo: memo, destinationTagInput: destinationTag)

        switch result {
        case let .valid(sendData):
            self.sendData = ExtendedSendData(sendData: sendData, address: resolvedAddress.address)
            cautions = []
        case let .invalid(cautions):
            sendData = nil
            self.cautions = cautions
        }
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
}

extension PreSendViewModel {
    public struct ExtendedSendData {
        public let sendData: SendData
        public let address: String?
    }

    // TODO: remove this, not needed for new send
    enum Mode {
        case regular
        case prefilled(address: String, amount: Decimal?)
        case predefined(address: String)

        var amount: Decimal? {
            switch self {
            case let .prefilled(_, amount): return amount
            default: return nil
            }
        }
    }
}
