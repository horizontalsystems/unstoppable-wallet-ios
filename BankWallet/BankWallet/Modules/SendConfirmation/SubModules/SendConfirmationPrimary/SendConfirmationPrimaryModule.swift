protocol ISendConfirmationPrimaryView: class {
    func set(primaryAmount: String?)
    func set(secondaryAmount: String?)
    func set(receiver: String)

    func showCopied()
}

protocol ISendConfirmationPrimaryViewDelegate {
    func viewDidLoad()
    func onCopyReceiverClick()
}

protocol ISendConfirmationPrimaryInteractor {
    func copy(receiver: String)
}
