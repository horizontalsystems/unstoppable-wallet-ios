class SendPresenter {
    weak var view: ISendView?

    private let interactor: ISendInteractor
    private let router: ISendRouter
    private let factory: ISendStateViewItemFactory
    private let userInput: SendUserInput

    init(interactor: ISendInteractor, router: ISendRouter, factory: ISendStateViewItemFactory, userInput: SendUserInput) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.userInput = userInput
    }

}

extension SendPresenter: ISendInteractorDelegate {

    func didSend() {
        view?.dismissWithSuccess()
    }

    func didFailToSend(error: Error) {
        view?.show(error: error)
    }

}

extension SendPresenter: ISendViewDelegate {

    func onViewDidLoad() {
        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state)

        view?.set(coin: interactor.coin)
        view?.set(amountInfo: viewItem.amountInfo)
        view?.set(switchButtonEnabled: viewItem.switchButtonEnabled)
        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(addressInfo: viewItem.addressInfo)
        view?.set(primaryFeeInfo: viewItem.primaryFeeInfo)
        view?.set(secondaryFeeInfo: viewItem.secondaryFeeInfo)
        view?.set(sendButtonEnabled: viewItem.sendButtonEnabled)
    }

    func onAmountChanged(amount: Double) {
        userInput.amount = amount

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state)

        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(primaryFeeInfo: viewItem.primaryFeeInfo)
        view?.set(secondaryFeeInfo: viewItem.secondaryFeeInfo)
        view?.set(sendButtonEnabled: viewItem.sendButtonEnabled)
    }

    func onSwitchClicked() {
        guard let convertedAmount = interactor.convertedAmount(forInputType: userInput.inputType, amount: userInput.amount) else {
            return
        }

        userInput.amount = convertedAmount
        userInput.inputType = userInput.inputType == .currency ? .coin : .currency

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state)

        view?.set(amountInfo: viewItem.amountInfo)
        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(primaryFeeInfo: viewItem.primaryFeeInfo)
        view?.set(secondaryFeeInfo: viewItem.secondaryFeeInfo)
    }

    func onPasteClicked() {
        if let address = interactor.addressFromPasteboard {
            onChange(address: address)
        }
    }

    func onScan(address: String) {
        onChange(address: address)
    }

    func onDeleteClicked() {
        onChange(address: nil)
    }

    func onSendClicked() {
        interactor.send(userInput: userInput)
    }

    private func onChange(address: String?) {
        userInput.address = address

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state)

        view?.set(addressInfo: viewItem.addressInfo)
        view?.set(primaryFeeInfo: viewItem.primaryFeeInfo)
        view?.set(secondaryFeeInfo: viewItem.secondaryFeeInfo)
        view?.set(sendButtonEnabled: viewItem.sendButtonEnabled)
    }

}
