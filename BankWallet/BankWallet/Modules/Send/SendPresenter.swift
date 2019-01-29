import Foundation

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

    private func onChange(address: String?) {
        userInput.address = address

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state)

        view?.set(addressInfo: viewItem.addressInfo)
        view?.set(amountInfo: viewItem.amountInfo)
        view?.set(primaryFeeInfo: viewItem.primaryFeeInfo)
        view?.set(secondaryFeeInfo: viewItem.secondaryFeeInfo)
        view?.set(sendButtonEnabled: viewItem.sendButtonEnabled)
    }

}

extension SendPresenter: ISendInteractorDelegate {

    func didUpdateRate() {
        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state)

        view?.set(switchButtonEnabled: viewItem.switchButtonEnabled)
        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(secondaryFeeInfo: viewItem.secondaryFeeInfo)
    }

    func didSend() {
        view?.dismissWithSuccess()
    }

    func didFailToSend(error: Error) {
        view?.show(error: error)
    }

}

extension SendPresenter: ISendViewDelegate {

    func onViewDidLoad() {
        userInput.inputType = interactor.defaultInputType

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state)

        view?.set(coinCode: interactor.coinCode)
        view?.set(amountInfo: viewItem.amountInfo)
        view?.set(switchButtonEnabled: viewItem.switchButtonEnabled)
        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(addressInfo: viewItem.addressInfo)
        view?.set(primaryFeeInfo: viewItem.primaryFeeInfo)
        view?.set(secondaryFeeInfo: viewItem.secondaryFeeInfo)
        view?.set(sendButtonEnabled: viewItem.sendButtonEnabled)

        interactor.fetchRate()
    }

    func onAmountChanged(amount: Decimal) {
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

        let newInputType: SendInputType = userInput.inputType == .currency ? .coin : .currency

        userInput.amount = convertedAmount
        userInput.inputType = newInputType

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state)

        view?.set(amountInfo: viewItem.amountInfo)
        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(primaryFeeInfo: viewItem.primaryFeeInfo)
        view?.set(secondaryFeeInfo: viewItem.secondaryFeeInfo)

        interactor.set(inputType: newInputType)
    }

    private func onAddressEnter(address: String) {
        let paymentAddress = interactor.parse(paymentAddress: address)
        if let amount = paymentAddress.amount {
            userInput.amount = amount
        }
        onChange(address: paymentAddress.address)
    }

    func onPasteClicked() {
        if let address = interactor.addressFromPasteboard {
            onAddressEnter(address: address)
        }
    }

    func onScan(address: String) {
        onAddressEnter(address: address)
    }

    func onDeleteClicked() {
        onChange(address: nil)
    }

    func onSendClicked() {
        let state = interactor.state(forUserInput: userInput)

        guard let viewItem = factory.confirmationViewItem(forState: state) else {
            return
        }

        view?.showConfirmation(viewItem: viewItem)
    }

    func onConfirmClicked() {
        interactor.send(userInput: userInput)
    }

    func onCopyAddress() {
        guard let address = userInput.address else {
            return
        }

        interactor.copy(address: address)
        view?.showCopied()
    }

    func onMaxClicked() {
        let totalBalanceMinusFee = interactor.totalBalanceMinusFee(forInputType: userInput.inputType, address: userInput.address)
        userInput.amount = totalBalanceMinusFee

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state)

        view?.set(amountInfo: viewItem.amountInfo)
        onAmountChanged(amount: totalBalanceMinusFee)
    }

}
