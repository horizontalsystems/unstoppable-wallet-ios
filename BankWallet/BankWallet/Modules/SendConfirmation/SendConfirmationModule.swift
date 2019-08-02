protocol ISendConfirmationDelegate: class {
    func onSendClicked(memo: String?)
}

protocol ISendConfirmationView: class {
    func showCopied()
    func dismissKeyboard()
}

protocol ISendConfirmationViewDelegate {
    func onSendClicked()
}

protocol ISendConfirmationInteractor {
    func copy(receiver: String)
}
