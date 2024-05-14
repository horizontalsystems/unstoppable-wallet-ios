import Combine
import Foundation
import MarketKit

class PreSendViewModel: ObservableObject {
    private let wallet: Wallet
    private let mode: Mode
    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit
    private let walletManager = App.shared.walletManager
    private let adapterManager = App.shared.adapterManager

    private var cancellables = Set<AnyCancellable>()

    @Published var currency: Currency

    var amount: Decimal? {
        didSet {
            syncFiatAmount()
            syncSendData()

            let amount = Decimal(string: amountString)

            if amount != self.amount {
                amountString = self.amount?.description ?? ""
            }
        }
    }

    @Published var amountString: String = "" {
        didSet {
            var amount = Decimal(string: amountString)

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

            let amount = Decimal(string: fiatAmountString)?.rounded(decimal: 2)

            if amount != fiatAmount {
                fiatAmountString = fiatAmount?.description ?? ""
            }
        }
    }

    @Published var fiatAmountString: String = "" {
        didSet {
            let amount = Decimal(string: fiatAmountString)?.rounded(decimal: 2)

            guard amount != fiatAmount else {
                return
            }

            enteringFiat = true

            fiatAmount = amount
        }
    }

    @Published var rate: Decimal? {
        didSet {
            syncFiatAmount()
        }
    }

    @Published var adapterState: AdapterState?
    @Published var availableBalance: Decimal?
    @Published var hasMemo = false

    private var enteringFiat = false

    @Published var address: String = ""
    @Published var addressResult: AddressInput.Result = .idle {
        didSet {
            syncAddressState()
        }
    }

    @Published var addressState: AddressState = .empty {
        didSet {
            syncHasMemo()
            syncSendData()
        }
    }

    @Published var addressCautionState: CautionState = .none

    @Published var memo: String = "" {
        didSet {
            syncSendData()
        }
    }

    var handler: IPreSendHandler?
    @Published var sendData: SendData?

    let addressVisible: Bool

    init(wallet: Wallet, mode: Mode) {
        self.wallet = wallet
        self.mode = mode

        handler = SendHandlerFactory.preSendHandler(wallet: wallet)
        currency = currencyManager.baseCurrency

        switch mode {
        case let .predefined(address):
            addressState = .valid(address: address)
            addressVisible = false
        default:
            addressVisible = true
        }

        defer {
            switch mode {
            case let .prefilled(address, amount):
                self.address = address
                self.amount = amount
            default: ()
            }
        }

        currencyManager.$baseCurrency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.currency = $0 }
            .store(in: &cancellables)

        rate = marketKit.coinPrice(coinUid: wallet.coin.uid, currencyCode: currency.code)?.value
        marketKit.coinPricePublisher(coinUid: wallet.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in self?.rate = price.value }
            .store(in: &cancellables)

        if let handler {
            adapterState = handler.state
            availableBalance = handler.balance
            hasMemo = handler.hasMemo(address: nil)

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

        guard let rate, let fiatAmount else {
            amount = nil
            return
        }

        amount = fiatAmount / rate
    }

    private func syncFiatAmount() {
        guard !enteringFiat else {
            return
        }

        guard let rate, let amount else {
            fiatAmount = nil
            return
        }

        fiatAmount = (amount * rate).rounded(decimal: 2)
    }

    private func syncAddressState() {
        switch addressResult {
        case .idle:
            addressState = .empty
            addressCautionState = .none
        case .loading, .invalid:
            addressState = .invalid
            addressCautionState = .none
        case let .valid(success):
            let address = success.address.raw
            addressState = .valid(address: address)
            addressCautionState = .none
        }
    }

    private func syncHasMemo() {
        guard let handler else {
            hasMemo = false
            return
        }

        hasMemo = handler.hasMemo(address: addressState.address)
    }
}

extension PreSendViewModel {
    var token: Token {
        wallet.token
    }

    func syncSendData() {
        guard let amount else {
            sendData = nil
            return
        }

        guard case let .valid(address) = addressState else {
            sendData = nil
            return
        }

        guard let handler else {
            sendData = nil
            return
        }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespaces)
        let memo = hasMemo && !trimmedMemo.isEmpty ? trimmedMemo : nil

        let result = handler.sendData(amount: amount, address: address, memo: memo)

        switch result {
        case let .valid(sendData):
            self.sendData = sendData
        case .invalid:
            sendData = nil
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

    enum AddressState {
        case empty
        case invalid
        case valid(address: String)

        var address: String? {
            switch self {
            case let .valid(address): return address
            default: return nil
            }
        }
    }
}
