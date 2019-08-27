class SendConfirmationPresenter {
    weak var delegate: ISendConfirmationDelegate?
    weak var view: ISendConfirmationView?

    init() {
    }

}

extension SendConfirmationPresenter: ISendConfirmationViewDelegate {

    func onSendClicked() {
        view?.dismissKeyboard()
        delegate?.onSendClicked()
    }

}
