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
    private let pasteboardManager: IPasteboardManager
    private let state: SendInteractorState

    init(currencyManager: ICurrencyManager, rateStorage: IRateStorage, pasteboardManager: IPasteboardManager, state: SendInteractorState) {
        self.currencyManager = currencyManager
        self.rateStorage = rateStorage
        self.pasteboardManager = pasteboardManager
        self.state = state
    }

}

extension SendInteractor: ISendInteractor {

    var coinCode: CoinCode {
        return state.wallet.coinCode
    }

    var addressFromPasteboard: String? {
        return pasteboardManager.value
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return state.wallet.adapter.parse(paymentAddress: paymentAddress)
    }

    func convertedAmount(forInputType inputType: SendInputType, amount: Double) -> Double? {
        guard let rateValue = state.rateValue else {
            return nil
        }

        switch inputType {
        case .coin: return amount * rateValue
        case .currency: return amount / rateValue
        }
    }

    func state(forUserInput input: SendUserInput) -> SendState {
        let coin = state.wallet.coinCode
        let adapter = state.wallet.adapter
        let baseCurrency = currencyManager.baseCurrency

        let sendState = SendState(inputType: input.inputType)

        switch input.inputType {
        case .coin:
            sendState.coinValue = CoinValue(coinCode: coin, value: input.amount)
            sendState.currencyValue = state.rateValue.map { CurrencyValue(currency: baseCurrency, value: input.amount * $0) }
        case .currency:
            sendState.coinValue = state.rateValue.map { CoinValue(coinCode: coin, value: input.amount / $0) }
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

        var feeValue: Double?
        if let coinValue = sendState.coinValue {
            do {
                feeValue = try adapter.fee(for: coinValue.value, address: input.address, senderPay: true)
            } catch FeeError.insufficientAmount(let fee) {
                feeValue = fee
                sendState.amountError = createAmountError(forInput: input, fee: fee)
            } catch {
                print("unhandled error: \(error)")
            }
        }
        if let feeValue = feeValue {
            sendState.feeCoinValue = CoinValue(coinCode: coinCode, value: feeValue)
        }

        if let rateValue = state.rateValue, let feeCoinValue = sendState.feeCoinValue {
            sendState.feeCurrencyValue = CurrencyValue(currency: baseCurrency, value: rateValue * feeCoinValue.value)
        }

        return sendState
    }

    func createAmountError(forInput input: SendUserInput, fee: Double) -> AmountError? {
        var balanceMinusFee = state.wallet.adapter.balance - fee
        if balanceMinusFee < 0 {
            balanceMinusFee = 0
        }
        switch input.inputType {
        case .coin:
            return AmountError.insufficientAmount(amountInfo: .coinValue(coinValue: CoinValue(coinCode: coinCode, value: balanceMinusFee)))
        case .currency:
            return state.rateValue.map {
                let currencyBalanceMinusFee = balanceMinusFee * $0
                return AmountError.insufficientAmount(amountInfo: .currencyValue(currencyValue: CurrencyValue(currency: currencyManager.baseCurrency, value: currencyBalanceMinusFee)))
            }
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

        var computedAmount: Double?

        if userInput.inputType == .coin {
            computedAmount = userInput.amount
        } else if let rateValue = state.rateValue {
            computedAmount = userInput.amount / rateValue
        }

        guard let amount = computedAmount else {
            delegate?.didFailToSend(error: SendError.noAmount)
            return
        }

        state.wallet.adapter.send(to: address, value: amount) { [weak self] error in
            if let error = error {
                self?.delegate?.didFailToSend(error: error)
            } else {
                self?.delegate?.didSend()
            }
        }
    }

    func fetchRate() {
        rateStorage.nonExpiredLatestRateValueObservable(forCoinCode: state.wallet.coinCode, currencyCode: currencyManager.baseCurrency.code)
                .take(1)
                .subscribe(onNext: { [weak self] rateValue in
                    self?.state.rateValue = rateValue
                    self?.delegate?.didUpdateRate()
                })
                .disposed(by: disposeBag)
    }

}
