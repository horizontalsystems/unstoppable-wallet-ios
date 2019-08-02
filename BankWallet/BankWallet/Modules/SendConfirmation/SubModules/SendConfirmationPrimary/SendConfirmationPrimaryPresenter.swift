class SendConfirmationPrimaryPresenter {
    private let interactor: ISendConfirmationPrimaryInteractor

    weak var view: ISendConfirmationPrimaryView?

    let primaryAmount: String
    let secondaryAmount: String?
    let receiver: String

    init(interactor: ISendConfirmationPrimaryInteractor, primaryAmount: String, secondaryAmount: String?, receiver: String) {
        self.interactor = interactor
        self.primaryAmount = primaryAmount
        self.secondaryAmount = secondaryAmount
        self.receiver = receiver
    }

}

extension SendConfirmationPrimaryPresenter: ISendConfirmationPrimaryViewDelegate {

    func viewDidLoad() {
        view?.set(primaryAmount: primaryAmount)
        view?.set(secondaryAmount: secondaryAmount)
        view?.set(receiver: receiver)
    }

    func onCopyReceiverClick() {
        interactor.copy(receiver: receiver)
        view?.showCopied()
    }

}
