protocol ISendConfirmationDelegate: class {
    func onSendClicked()
    func onCancelClicked()
}

protocol ISendConfirmationView: class {
    func show(viewItem: SendConfirmationAmountViewItem, last: Bool)
    func show(viewItem: SendConfirmationMemoViewItem)
    func show(viewItem: SendConfirmationFeeViewItem, first: Bool)
    func show(viewItem: SendConfirmationTotalViewItem, first: Bool)
    func show(viewItem: SendConfirmationDurationViewItem, first: Bool)

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
