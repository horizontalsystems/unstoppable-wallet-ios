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
    private let wallet: Wallet
    private var rate: Rate?

    init(currencyManager: ICurrencyManager, rateStorage: IRateStorage, pasteboardManager: IPasteboardManager, wallet: Wallet) {
        self.currencyManager = currencyManager
        self.rateStorage = rateStorage
        self.pasteboardManager = pasteboardManager
        self.wallet = wallet
    }

}

extension SendInteractor: ISendInteractor {

    var coinCode: CoinCode {
        return wallet.coinCode
    }

    var addressFromPasteboard: String? {
        return pasteboardManager.value
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return wallet.adapter.parse(paymentAddress: paymentAddress)
    }

    func convertedAmount(forInputType inputType: SendInputType, amount: Double) -> Double? {
        guard let rate = rate else {
            return nil
        }

        switch inputType {
        case .coin: return amount * rate.value
        case .currency: return amount / rate.value
        }
    }

    func state(forUserInput input: SendUserInput) -> SendState {
        let coin = wallet.coinCode
        let adapter = wallet.adapter
        let baseCurrency = currencyManager.baseCurrency
        let rateValue = rate?.value

        let state = SendState(inputType: input.inputType)

        switch input.inputType {
        case .coin:
            state.coinValue = CoinValue(coinCode: coin, value: input.amount)
            state.currencyValue = rateValue.map { CurrencyValue(currency: baseCurrency, value: input.amount * $0) }

            let balance = adapter.balance
            if balance < input.amount {
                state.amountError = AmountError.insufficientAmount(amountInfo: .coinValue(coinValue: CoinValue(coinCode: coin, value: balance)))
            }
        case .currency:
            state.coinValue = rateValue.map { CoinValue(coinCode: coin, value: input.amount / $0) }
            state.currencyValue = CurrencyValue(currency: baseCurrency, value: input.amount)

            if let rateValue = rateValue {
                let currencyBalance = adapter.balance * rateValue
                if currencyBalance < input.amount {
                    state.amountError = AmountError.insufficientAmount(amountInfo: .currencyValue(currencyValue: CurrencyValue(currency: baseCurrency, value: currencyBalance)))
                }
            }
        }

        state.address = input.address

        if let address = input.address {
            do {
                try adapter.validate(address: address)
            } catch {
                state.addressError = .invalidAddress
            }
        }

        if let coinValue = state.coinValue, let fee = try? adapter.fee(for: coinValue.value, address: input.address, senderPay: true) {
            state.feeCoinValue = CoinValue(coinCode: coin, value: fee)
        }

        if let rateValue = rateValue, let feeCoinValue = state.feeCoinValue {
            state.feeCurrencyValue = CurrencyValue(currency: baseCurrency, value: rateValue * feeCoinValue.value)
        }

        return state
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
        } else if let rateValue = rate?.value {
            computedAmount = userInput.amount / rateValue
        }

        guard let amount = computedAmount else {
            delegate?.didFailToSend(error: SendError.noAmount)
            return
        }

        wallet.adapter.send(to: address, value: amount) { [weak self] error in
            if let error = error {
                self?.delegate?.didFailToSend(error: error)
            } else {
                self?.delegate?.didSend()
            }
        }
    }

    func fetchRate() {
        rateStorage.rateObservable(forCoinCode: wallet.coinCode, currencyCode: currencyManager.baseCurrency.code)
                .take(1)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] rate in
                    if !rate.expired {
                        self?.rate = rate
                        self?.delegate?.didUpdateRate()
                    }
                })
                .disposed(by: disposeBag)
    }

}
