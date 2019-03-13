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
        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)

        view?.set(addressInfo: viewItem.addressInfo)
        view?.set(amountInfo: viewItem.amountInfo)
        view?.set(feeInfo: viewItem.feeInfo)
        view?.set(sendButtonEnabled: viewItem.sendButtonEnabled)
    }

}

extension SendPresenter: ISendInteractorDelegate {

    func didUpdateRate() {
        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)

        view?.set(switchButtonEnabled: viewItem.switchButtonEnabled)
        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(feeInfo: viewItem.feeInfo)
    }

    func didSend() {
        view?.dismissWithSuccess()
    }

    func didFailToSend(error: Error) {
        view?.show(error: error)
    }

}

extension SendPresenter: ISendViewDelegate {

    var isFeeAdjustable: Bool {
        return true
    }

    func onViewDidLoad() {
        interactor.fetchRate()

        userInput.inputType = interactor.defaultInputType

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)

        view?.set(coin: interactor.coin)
        view?.set(decimal: viewItem.decimal)
        view?.set(amountInfo: viewItem.amountInfo)
        view?.set(switchButtonEnabled: viewItem.switchButtonEnabled)
        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(addressInfo: viewItem.addressInfo)
        view?.set(feeInfo: viewItem.feeInfo)
        view?.set(sendButtonEnabled: viewItem.sendButtonEnabled)
    }

    func onAmountChanged(amount: Decimal) {
        userInput.amount = amount

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)

        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(feeInfo: viewItem.feeInfo)
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
        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)

        view?.set(decimal: viewItem.decimal)
        view?.set(amountInfo: viewItem.amountInfo)
        view?.set(hintInfo: viewItem.hintInfo)
        view?.set(feeInfo: viewItem.feeInfo)

        interactor.set(inputType: newInputType)
    }

    private func onAddressEnter(address: String) {
        let paymentAddress = interactor.parse(paymentAddress: address)
        if let amount = paymentAddress.amount {
            userInput.amount = amount
        }
        onChange(address: paymentAddress.address)
    }

    func onPasteAddressClicked() {
        if let address = interactor.valueFromPasteboard {
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

        guard let viewItem = factory.confirmationViewItem(forState: state, coin: interactor.coin) else {
            return
        }

        view?.showConfirmation(viewItem: viewItem)
    }

    func onConfirmClicked() {
        view?.showProgress()
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
        let totalBalanceMinusFee = interactor.totalBalanceMinusFee(forInputType: userInput.inputType, address: userInput.address, feeRatePriority: userInput.feeRatePriority)
        userInput.amount = totalBalanceMinusFee

        let state = interactor.state(forUserInput: userInput)
        let viewItem = factory.viewItem(forState: state, forceRoundDown: true)

        view?.set(amountInfo: viewItem.amountInfo)
    }

    func onPasteAmountClicked() {
        if let value = ValueFormatter.instance.parseAnyDecimal(from: interactor.valueFromPasteboard) {
            userInput.amount = value

            let state = interactor.state(forUserInput: userInput)
            let viewItem = factory.viewItem(forState: state, forceRoundDown: false)

            view?.set(amountInfo: viewItem.amountInfo)
        }
    }

    func onFeePriorityChange(value: Int) {
        userInput.feeRatePriority = FeeRatePriority(rawValue: value) ?? .medium
    }

}
