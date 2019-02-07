import RxSwift

class SendInteractor {
    enum SendError: Error {
        case noAddress
        case noAmount
    }

    private let disposeBag = DisposeBag()

    weak var delegate: ISendInteractorDelegate?

    private let currencyManager: ICurrencyManager
    private let rateStorage: IRateStorage
    private let localStorage: ILocalStorage
    private let pasteboardManager: IPasteboardManager
    private let appConfigProvider: IAppConfigProvider
    private let state: SendInteractorState

    init(currencyManager: ICurrencyManager, rateStorage: IRateStorage, localStorage: ILocalStorage, pasteboardManager: IPasteboardManager, state: SendInteractorState, appConfigProvider: IAppConfigProvider) {
        self.currencyManager = currencyManager
        self.rateStorage = rateStorage
        self.localStorage = localStorage
        self.pasteboardManager = pasteboardManager
        self.appConfigProvider = appConfigProvider
        self.state = state
    }

}

extension SendInteractor: ISendInteractor {

    var defaultInputType: SendInputType {
        if state.rateValue == nil {
            return .coin
        }
        return localStorage.sendInputType ?? .coin
    }

    var coin: Coin {
        return state.adapter.coin
    }

    var valueFromPasteboard: String? {
        return pasteboardManager.value
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return state.adapter.parse(paymentAddress: paymentAddress)
    }

    func convertedAmount(forInputType inputType: SendInputType, amount: Decimal) -> Decimal? {
        guard let rateValue = state.rateValue else {
            return nil
        }

        switch inputType {
        case .coin: return amount * rateValue
        case .currency: return amount / rateValue
        }
    }

    func state(forUserInput input: SendUserInput) -> SendState {
        let coinCode = state.adapter.coin.code
        let adapter = state.adapter
        let baseCurrency = currencyManager.baseCurrency

        let decimal = input.inputType == .coin ? min(adapter.decimal, appConfigProvider.maxDecimal) : appConfigProvider.fiatDecimal

        let sendState = SendState(decimal: decimal, inputType: input.inputType)

        switch input.inputType {
        case .coin:
            sendState.coinValue = CoinValue(coinCode: coinCode, value: input.amount)
            sendState.currencyValue = state.rateValue.map { CurrencyValue(currency: baseCurrency, value: input.amount * $0) }
        case .currency:
            sendState.coinValue = state.rateValue.map { CoinValue(coinCode: coinCode, value: input.amount / $0) }
            sendState.currencyValue = CurrencyValue(currency: baseCurrency, value: input.amount)
        }

        sendState.address = input.address

        if let address = input.address {
            do {
                try adapter.validate(address: address)
            } catch {
                sendState.addressError = .invalidAddress
            }
        }

        let errors = adapter.validate(amount: sendState.coinValue?.value ?? 0, address: input.address)
        errors.forEach {
            switch($0) {
            case .insufficientAmount: sendState.amountError = createAmountError(forInput: input)
            case .insufficientFeeBalance: break//sendState.feeError = createAmountError(forInput: input)
            }
        }
        if let coinValue = sendState.coinValue {
            let feeValue = adapter.fee(for: coinValue.value, address: input.address)
            sendState.feeCoinValue = CoinValue(coinCode: coinCode, value: feeValue)
        }
        if let rateValue = state.rateValue, let feeCoinValue = sendState.feeCoinValue {
            sendState.feeCurrencyValue = CurrencyValue(currency: baseCurrency, value: rateValue * feeCoinValue.value)
        }

        return sendState
    }

    private func createAmountError(forInput input: SendUserInput) -> AmountError? {
        let availableBalance = state.adapter.availableBalance(for: input.address)
        switch input.inputType {
        case .coin:
            return .insufficientAmount(amountInfo: .coinValue(coinValue: CoinValue(coinCode: coin.code, value: availableBalance)))
        case .currency:
            return state.rateValue.map {
                let currencyBalanceMinusFee = availableBalance * $0
                return .insufficientAmount(amountInfo: .currencyValue(currencyValue: CurrencyValue(currency: currencyManager.baseCurrency, value: currencyBalanceMinusFee)))
            }
        }
    }

    func totalBalanceMinusFee(forInputType input: SendInputType, address: String?) -> Decimal {
        let availableBalance =  state.adapter.availableBalance(for: address)
        switch input {
        case .coin:
            return availableBalance
        case .currency:
            return state.rateValue.map {
                return availableBalance * $0
            } ?? 0
        }
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

    func send(userInput: SendUserInput) {
        guard let address = userInput.address else {
            delegate?.didFailToSend(error: SendError.noAddress)
            return
        }

        var computedAmount: Decimal?

        if userInput.inputType == .coin {
            computedAmount = userInput.amount
        } else if let rateValue = state.rateValue {
            computedAmount = userInput.amount / rateValue
        }

        guard let amount = computedAmount else {
            delegate?.didFailToSend(error: SendError.noAmount)
            return
        }

        state.adapter.send(to: address, value: amount) { [weak self] error in
            if let error = error {
                self?.delegate?.didFailToSend(error: error)
            } else {
                self?.delegate?.didSend()
            }
        }
    }

    func set(inputType: SendInputType) {
        localStorage.sendInputType = inputType
    }

    func fetchRate() {
        rateStorage.nonExpiredLatestRateValueObservable(forCoinCode: state.adapter.coin.code, currencyCode: currencyManager.baseCurrency.code)
                .take(1)
                .subscribe(onNext: { [weak self] rateValue in
                    self?.state.rateValue = rateValue
                    self?.delegate?.didUpdateRate()
                })
                .disposed(by: disposeBag)
    }

}
