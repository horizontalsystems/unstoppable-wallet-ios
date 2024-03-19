
protocol ISendConfirmationViewItemNew {}

struct SendConfirmationAmountViewItem: ISendConfirmationViewItemNew {
    let coinValue: CoinValue
    let currencyValue: CurrencyValue?
    let receiver: Address
    let isAccount: Bool
    let sentToSelf: Bool

    init(coinValue: CoinValue, currencyValue: CurrencyValue?, receiver: Address, isAccount: Bool = false, sentToSelf: Bool = false) {
        self.coinValue = coinValue
        self.currencyValue = currencyValue
        self.receiver = receiver
        self.isAccount = isAccount
        self.sentToSelf = sentToSelf
    }
}

struct SendConfirmationFeeViewItem: ISendConfirmationViewItemNew {
    let coinValue: CoinValue
    let currencyValue: CurrencyValue?
}

struct SendConfirmationMemoViewItem: ISendConfirmationViewItemNew {
    let memo: String
}

struct SendConfirmationLockUntilViewItem: ISendConfirmationViewItemNew {
    let lockValue: String
}

struct SendConfirmationDisabledRbfViewItem: ISendConfirmationViewItemNew {}

struct ReplacedTransactionHashViewItem: ISendConfirmationViewItemNew {
    let hashes: [String]
}
