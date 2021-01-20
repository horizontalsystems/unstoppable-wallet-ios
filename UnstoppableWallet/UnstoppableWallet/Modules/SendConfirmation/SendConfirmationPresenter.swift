class SendConfirmationPresenter {
    private let interactor: ISendConfirmationInteractor

    weak var delegate: ISendConfirmationDelegate?
    weak var view: ISendConfirmationView?

    private let viewItems: [ISendConfirmationViewItemNew]

    init(interactor: ISendConfirmationInteractor, viewItems: [ISendConfirmationViewItemNew]) {
        self.interactor = interactor
        self.viewItems = viewItems
    }

}

extension SendConfirmationPresenter: ISendConfirmationViewDelegate {

    func viewDidLoad() {
        viewItems.forEach { item in
            switch item {
            case let item as SendConfirmationAmountViewItem: self.view?.show(viewItem: item)
            case let item as SendConfirmationMemoViewItem: self.view?.show(viewItem: item)
            case let item as SendConfirmationFeeViewItem: self.view?.show(viewItem: item)
            case let item as SendConfirmationTotalViewItem: self.view?.show(viewItem: item)
            case let item as SendConfirmationLockUntilViewItem: self.view?.show(viewItem: item)
            default: ()
            }
        }

        view?.buildData()
    }

    func onCopy(receiver: String) {
        interactor.copy(receiver: receiver)
        view?.showCopied()
    }

    func onSendClicked() {
        delegate?.onSendClicked()
    }

    func onCancelClicked() {
        delegate?.onCancelClicked()
    }

}
