protocol ISendConfirmationDelegate: class {
    func onSendClicked()
    func onCancelClicked()
}

protocol ISendConfirmationView: class {
    func show(viewItem: SendConfirmationAmountViewItem)
    func show(viewItem: SendConfirmationMemoViewItem)
    func show(viewItem: SendConfirmationFeeViewItem)
    func show(viewItem: SendConfirmationTotalViewItem)
    func show(viewItem: SendConfirmationLockUntilViewItem)

    func buildData()
    func showCopied()
}

protocol ISendConfirmationViewDelegate {
    func viewDidLoad()
    func onCopy(receiver: String)
    func onSendClicked()
    func onCancelClicked()
}

protocol ISendConfirmationInteractor {
    func copy(receiver: String)
}
