protocol ISendConfirmationViewItemNew {}

struct SendConfirmationAmountViewItem: ISendConfirmationViewItemNew {
    let primaryInfo: AmountInfo
    let secondaryInfo: AmountInfo?
    let receiver: Address
    let isAccount: Bool

    init(primaryInfo: AmountInfo, secondaryInfo: AmountInfo?, receiver: Address, isAccount: Bool = false) {
        self.primaryInfo = primaryInfo
        self.secondaryInfo = secondaryInfo
        self.receiver = receiver
        self.isAccount = isAccount
    }

}

struct SendConfirmationFeeViewItem: ISendConfirmationViewItemNew {
    let primaryInfo: AmountInfo
    var secondaryInfo: AmountInfo?
}

struct SendConfirmationTotalViewItem: ISendConfirmationViewItemNew {
    let primaryInfo: AmountInfo
    var secondaryInfo: AmountInfo?
}

struct SendConfirmationMemoViewItem: ISendConfirmationViewItemNew {
    let memo: String
}

struct SendConfirmationLockUntilViewItem: ISendConfirmationViewItemNew {
    let lockValue: String
}
