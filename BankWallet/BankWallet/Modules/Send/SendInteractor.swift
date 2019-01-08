class SendInteractor {
    enum SendError: Error {
        case noAddress
        case noAmount
    }

    weak var delegate: ISendInteractorDelegate?

    private let currencyManager: ICurrencyManager
    private let pasteboardManager: IPasteboardManager
    private let wallet: Wallet
    private var rate: Rate?

    init(currencyManager: ICurrencyManager, rateManager: IRateManager, pasteboardManager: IPasteboardManager, wallet: Wallet) {
        self.currencyManager = currencyManager
        self.pasteboardManager = pasteboardManager
        self.wallet = wallet

        if let rate = rateManager.rate(forCoin: wallet.coinCode, currencyCode: currencyManager.baseCurrency.code), !rate.expired {
            self.rate = rate
        }
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
        case .currency:
            state.coinValue = rateValue.map { CoinValue(coinCode: coin, value: input.amount / $0) }
            state.currencyValue = CurrencyValue(currency: baseCurrency, value: input.amount)
        }

        state.address = input.address

        if let address = input.address {
            do {
                try adapter.validate(address: address)
            } catch {
                state.addressError = .invalidAddress
            }
        }

        var feeValue: Double?
        if let coinValue = state.coinValue {
            do {
                feeValue = try adapter.fee(for: coinValue.value, address: input.address, senderPay: true)
            } catch FeeError.insufficientAmount(let fee) {
                feeValue = fee
                state.amountError = createAmountError(forInput: input, fee: fee)
            } catch {
                print("unhandled error: \(error)")
            }
        }
        if let feeValue = feeValue {
            state.feeCoinValue = CoinValue(coinCode: coinCode, value: feeValue)
        }

        if let rateValue = rateValue, let feeCoinValue = state.feeCoinValue {
            state.feeCurrencyValue = CurrencyValue(currency: baseCurrency, value: rateValue * feeCoinValue.value)
        }

        return state
    }

    func createAmountError(forInput input: SendUserInput, fee: Double) -> AmountError? {
        var balanceMinusFee = wallet.adapter.balance - fee
        if balanceMinusFee < 0 {
            balanceMinusFee = 0
        }
        switch input.inputType {
        case .coin:
            return AmountError.insufficientAmount(amountInfo: .coinValue(coinValue: CoinValue(coinCode: coinCode, value: balanceMinusFee)))
        case .currency:
            return (rate?.value).map {
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

}
