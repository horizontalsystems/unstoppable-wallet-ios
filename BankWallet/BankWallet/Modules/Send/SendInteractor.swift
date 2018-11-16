class SendInteractor {
    weak var delegate: ISendInteractorDelegate?

    private let currencyManager: ICurrencyManager
    private let rateManager: IRateManager
    private let pasteboardManager: IPasteboardManager
    private let wallet: Wallet

    init(currencyManager: ICurrencyManager, rateManager: IRateManager, pasteboardManager: IPasteboardManager, wallet: Wallet) {
        self.currencyManager = currencyManager
        self.rateManager = rateManager
        self.pasteboardManager = pasteboardManager
        self.wallet = wallet
    }

}

extension SendInteractor: ISendInteractor {

    var coin: Coin {
        return wallet.coin
    }

    var addressFromPasteboard: String? {
        return pasteboardManager.value
    }

    func convertedAmount(forInputType inputType: SendInputType, amount: Double) -> Double? {
        guard let rate = rateManager.rate(forCoin: wallet.coin, currencyCode: currencyManager.baseCurrency.code) else {
            return nil
        }

        switch inputType {
        case .coin: return amount * rate.value
        case .currency: return amount / rate.value
        }
    }

    func state(forUserInput input: SendUserInput) -> SendState {
        let coin = wallet.coin
        let adapter = wallet.adapter
        let baseCurrency = currencyManager.baseCurrency
        let rateValue = rateManager.rate(forCoin: coin, currencyCode: baseCurrency.code)?.value

        let state = SendState(inputType: input.inputType)

        switch input.inputType {
        case .coin:
            state.coinValue = CoinValue(coin: coin, value: input.amount)
            state.currencyValue = rateValue.map { CurrencyValue(currency: baseCurrency, value: input.amount * $0) }

            let balance = adapter.balance
            if balance < input.amount {
                state.amountError = AmountError.insufficientAmount(amountInfo: .coinValue(coinValue: CoinValue(coin: coin, value: balance)))
            }
        case .currency:
            state.coinValue = rateValue.map { CoinValue(coin: coin, value: input.amount / $0) }
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
            state.feeCoinValue = CoinValue(coin: coin, value: fee)
        }

        if let rateValue = rateValue, let feeCoinValue = state.feeCoinValue {
            state.feeCurrencyValue = CurrencyValue(currency: baseCurrency, value: rateValue * feeCoinValue.value)
        }

        return state
    }

    func send(userInput: SendUserInput) {
        guard let rateValue = rateManager.rate(forCoin: wallet.coin, currencyCode: currencyManager.baseCurrency.code)?.value else {
            return
        }
        guard let address = userInput.address else {
            return
        }

        let amount = userInput.inputType == .coin ? userInput.amount : userInput.amount / rateValue

        wallet.adapter.send(to: address, value: amount) { [weak self] error in
            if let error = error {
                self?.delegate?.didFailToSend(error: error)
            } else {
                self?.delegate?.didSend()
            }
        }
    }

}
