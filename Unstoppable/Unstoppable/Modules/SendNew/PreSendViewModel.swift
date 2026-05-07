import Combine
import Foundation
import MarketKit

class PreSendViewModel: ObservableObject {
    private let wallet: Wallet
    let resolvedAddress: ResolvedAddress
    private let currencyManager = Core.shared.currencyManager
    private let marketKit = Core.shared.marketKit
    private let walletManager = Core.shared.walletManager
    private let adapterManager = Core.shared.adapterManager
    private let decimalParser = AmountDecimalParser()

    private var cancellables = Set<AnyCancellable>()

    @Published var currency: Currency

    var amount: Decimal? {
        didSet {
            syncFiatAmount()
            syncSendData()

            let amount = decimalParser.parseAnyDecimal(from: amountString)

            if amount != self.amount {
                amountString = self.amount?.description ?? ""
            }
        }
    }

    @Published var amountString: String = "" {
        didSet {
            var amount = decimalParser.parseAnyDecimal(from: amountString)

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

            let amount = decimalParser.parseAnyDecimal(from: fiatAmountString)?.rounded(decimal: 2)

            if amount != fiatAmount {
                fiatAmountString = fiatAmount?.description ?? ""
            }
        }
    }

    @Published var fiatAmountString: String = "" {
        didSet {
            let amount = decimalParser.parseAnyDecimal(from: fiatAmountString)?.rounded(decimal: 2)

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

    @Published var adapterState: AdapterState?
    @Published var availableBalance: Decimal?
    @Published var hasMemo = false

    private var enteringFiat = false

    @Published var memo: String = "" {
        didSet {
            syncSendData()
        }
    }

    var handler: IPreSendHandler?
    @Published var sendData: ExtendedSendData?
    @Published var cautions = [CautionNew]()

    init(wallet: Wallet, handler: IPreSendHandler?, resolvedAddress: ResolvedAddress, amount: Decimal?, memo: String?) {
        self.wallet = wallet
        self.handler = handler
        self.resolvedAddress = resolvedAddress

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
            hasMemo = handler.hasMemo(address: resolvedAddress.address)

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

        syncFiatAmount()
    }

    private func syncAmount() {
        guard enteringFiat else {
            return
        }

        guard let coinPrice, let fiatAmount else {
            amount = nil
            return
        }

        amount = fiatAmount / coinPrice.value
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

    private func syncHasMemo() {
        guard let handler else {
            hasMemo = false
            return
        }

        hasMemo = handler.hasMemo(address: resolvedAddress.address)
    }
}

extension PreSendViewModel {
    var token: Token {
        wallet.token
    }

    var title: String {
        handler?.title(token.coin.code) ?? "send.send".localized
    }

    func syncSendData() {
        guard let amount else {
            sendData = nil
            return
        }

        // guard case let .valid(address) = addressState else {
        //     sendData = nil
        //     return
        // }

        guard let handler else {
            sendData = nil
            return
        }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespaces)
        let memo = hasMemo && !trimmedMemo.isEmpty ? trimmedMemo : nil

        let result = handler.sendData(amount: amount, address: resolvedAddress.address, memo: memo)

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

        amount = (availableBalance * Decimal(percent) / 100).rounded(decimal: token.decimals)
    }

    func clearAmountIn() {
        enteringFiat = false
        amount = nil
    }
}

extension PreSendViewModel {
    struct ExtendedSendData {
        let sendData: SendData
        let address: String?
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
