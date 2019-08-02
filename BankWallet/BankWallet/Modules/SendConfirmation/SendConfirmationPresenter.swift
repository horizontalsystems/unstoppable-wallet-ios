class SendConfirmationPresenter {
    weak var delegate: ISendConfirmationDelegate?
    weak var view: ISendConfirmationView?

    private let memoModule: ISendConfirmationMemoModule?

    init(memoModule: ISendConfirmationMemoModule?) {
        self.memoModule = memoModule
    }

}

extension SendConfirmationPresenter: ISendConfirmationViewDelegate {

    func onSendClicked() {
        view?.dismissKeyboard()
        delegate?.onSendClicked(memo: memoModule?.memo)
    }

}
