
protocol ISendConfirmationViewItemNew {}

struct SendConfirmationAmountViewItem: ISendConfirmationViewItemNew {
    let appValue: AppValue
    let currencyValue: CurrencyValue?
    let receiver: Address
    let isAccount: Bool
    let sentToSelf: Bool

    init(appValue: AppValue, currencyValue: CurrencyValue?, receiver: Address, isAccount: Bool = false, sentToSelf: Bool = false) {
        self.appValue = appValue
        self.currencyValue = currencyValue
        self.receiver = receiver
        self.isAccount = isAccount
        self.sentToSelf = sentToSelf
    }
}

struct SendConfirmationFeeViewItem: ISendConfirmationViewItemNew {
    let appValue: AppValue
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
