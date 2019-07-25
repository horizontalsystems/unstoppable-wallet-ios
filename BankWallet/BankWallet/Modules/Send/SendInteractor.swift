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
    private let async: Bool

    init(currencyManager: ICurrencyManager, rateStorage: IRateStorage, localStorage: ILocalStorage, pasteboardManager: IPasteboardManager, state: SendInteractorState, appConfigProvider: IAppConfigProvider, backgroundManager: BackgroundManager, async: Bool = true) {
        self.currencyManager = currencyManager
        self.rateStorage = rateStorage
        self.localStorage = localStorage
        self.pasteboardManager = pasteboardManager
        self.appConfigProvider = appConfigProvider
        self.state = state
        self.async = async

        backgroundManager.didBecomeActiveSubject.subscribe(onNext: { [weak self] in
            self?.delegate?.onBecomeActive()
        }).disposed(by: disposeBag)
    }

}

extension SendInteractor: ISendInteractor {

    func availableBalance(params: [String: Any]) throws -> Decimal {
        return try state.adapter.availableBalance(params: params)
    }

    var defaultInputType: SendInputType {
        if state.exchangeRate == nil {
            return .coin
        }
        return localStorage.sendInputType ?? .coin
    }

    var coin: Coin {
        return state.adapter.wallet.coin
    }

    var valueFromPasteboard: String? {
        return pasteboardManager.value
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return state.adapter.parse(paymentAddress: paymentAddress)
    }

    func convertedAmount(forInputType inputType: SendInputType, amount: Decimal) -> Decimal? {
        guard let rateValue = state.exchangeRate?.value else {
            return nil
        }

        switch inputType {
        case .coin: return amount * rateValue
        case .currency: return amount / rateValue
        }
    }

    func decimal(forInputType inputType: SendInputType) -> Int {
        return inputType == .coin ? min(state.adapter.decimal, appConfigProvider.maxDecimal) : appConfigProvider.fiatDecimal
    }

    func state(forUserInput input: SendUserInput) throws -> SendState {
        let adapter = state.adapter
        let coinCode = adapter.wallet.coin.code
        let baseCurrency = currencyManager.baseCurrency
        let rateValue = state.exchangeRate?.value

        let decimal = input.inputType == .coin ? min(adapter.decimal, appConfigProvider.maxDecimal) : appConfigProvider.fiatDecimal

        let sendState = SendState(decimal: decimal, inputType: input.inputType)

        switch input.inputType {
        case .coin:
            sendState.coinValue = CoinValue(coinCode: coinCode, value: input.amount)
            sendState.currencyValue = rateValue.map { CurrencyValue(currency: baseCurrency, value: input.amount * $0) }
        case .currency:
            sendState.coinValue = rateValue.map { CoinValue(coinCode: coinCode, value: input.amount / $0) }
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

        var params = [String: Any]()
        params[AdapterFields.amount.rawValue] = sendState.coinValue?.value ?? 0
        params[AdapterFields.address.rawValue] = input.address
        params[AdapterFields.feeRateRriority.rawValue] = input.feeRatePriority
        let errors = try adapter.validate(params: params)
        try errors.forEach {
            switch($0) {
            case .insufficientAmount: sendState.amountError = try createAmountError(forInput: input, feeRatePriority: input.feeRatePriority)
            case .insufficientFeeBalance: sendState.feeError = try createFeeError(forInput: input, amount: sendState.coinValue?.value ?? 0, feeRatePriority: input.feeRatePriority)
            }
        }
        if let coinValue = sendState.coinValue {
            params[AdapterFields.amount.rawValue] = coinValue.value
            let feeValue = try adapter.fee(params: params)
            sendState.feeCoinValue = CoinValue(coinCode: state.adapter.feeCoinCode ?? coinCode, value: feeValue)
        }
        let feeRateValue: Decimal?
        if state.adapter.feeCoinCode != nil {
            feeRateValue = state.feeExchangeRate?.value
        } else {
            feeRateValue = rateValue
        }
        if let rateValue = feeRateValue, let feeCoinValue = sendState.feeCoinValue {
            sendState.feeCurrencyValue = CurrencyValue(currency: baseCurrency, value: rateValue * feeCoinValue.value)
        }

        return sendState
    }

    private func createAmountError(forInput input: SendUserInput, feeRatePriority: FeeRatePriority) throws -> AmountInfo? {
        var params = [String: Any]()
        params[AdapterFields.address.rawValue] = input.address
        params[AdapterFields.feeRateRriority.rawValue] = input.feeRatePriority

        let availableBalance = try state.adapter.availableBalance(params: params)
        switch input.inputType {
        case .coin:
            return .coinValue(coinValue: CoinValue(coinCode: coin.code, value: availableBalance))
        case .currency:
            return state.exchangeRate.map {
                let currencyBalanceMinusFee = availableBalance * $0.value
                return .currencyValue(currencyValue: CurrencyValue(currency: currencyManager.baseCurrency, value: currencyBalanceMinusFee))
            }
        }
    }

    private func createFeeError(forInput input: SendUserInput, amount: Decimal, feeRatePriority: FeeRatePriority) throws -> FeeError? {
        guard let code = state.adapter.feeCoinCode else {
            return nil
        }
        var params = [String: Any]()
        params[AdapterFields.amount.rawValue] = amount
        params[AdapterFields.address.rawValue] = input.address
        params[AdapterFields.feeRateRriority.rawValue] = input.feeRatePriority

        let fee = try state.adapter.fee(params: params)
        let feeValue = CoinValue(coinCode: code, value: fee)
        return .erc20error(erc20CoinCode: state.adapter.wallet.coin.code, fee: feeValue)
    }

    func totalBalanceMinusFee(forInputType input: SendInputType, address: String?, feeRatePriority: FeeRatePriority) throws -> Decimal {
        var params = [String: Any]()
        params[AdapterFields.address.rawValue] = address
        params[AdapterFields.feeRateRriority.rawValue] = feeRatePriority

        let availableBalance = try state.adapter.availableBalance(params: params)
        switch input {
        case .coin:
            return availableBalance
        case .currency:
            return state.exchangeRate.map {
                return availableBalance * $0.value
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
        } else if let rateValue = state.exchangeRate?.value {
            computedAmount = userInput.amount / rateValue
        }

        guard let amount = computedAmount else {
            delegate?.didFailToSend(error: SendError.noAmount)
            return
        }

        var params = [String: Any]()
        params[AdapterFields.amount.rawValue] = amount
        params[AdapterFields.address.rawValue] = userInput.address
        params[AdapterFields.feeRateRriority.rawValue] = userInput.feeRatePriority

        var single = state.adapter.sendSingle(params: params)
        if async {
            single = single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .observeOn(MainScheduler.instance)
        }
        single.subscribe(onSuccess: { [weak self] in
                    self?.delegate?.didSend()
                }, onError: { [weak self] error in
                    self?.delegate?.didFailToSend(error: error)
                })
                .disposed(by: disposeBag)
    }

    func set(inputType: SendInputType) {
        localStorage.sendInputType = inputType
    }

    func retrieveRate() {
//        rateStorage.nonExpiredLatestRateObservable(forCoinCode: state.adapter.wallet.coin.code, currencyCode: currencyManager.baseCurrency.code)
//                .take(1)
//                .subscribe(onNext: { [weak self] rate in
//                    self?.state.exchangeRate = rate
//                    self?.delegate?.didRetrieve(rate: rate)
//                })
//                .disposed(by: disposeBag)
//
//        if let feeCoinCode = state.adapter.feeCoinCode {
//            rateStorage.nonExpiredLatestRateObservable(forCoinCode: feeCoinCode, currencyCode: currencyManager.baseCurrency.code)
//                    .take(1)
//                    .subscribe(onNext: { [weak self] rateValue in
//                        self?.state.feeExchangeRate = rateValue
//                        self?.delegate?.didRetrieveFeeRate()
//                    })
//                    .disposed(by: disposeBag)
//        }
    }

}
