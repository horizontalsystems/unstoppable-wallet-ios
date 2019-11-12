import Foundation
import RxSwift

class SendEthereumHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendEthereumInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule
    private let feePriorityModule: ISendFeePriorityModule

    init(interactor: ISendEthereumInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule, feePriorityModule: ISendFeePriorityModule) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
        self.feePriorityModule = feePriorityModule
    }

    private func syncValidation() {
        do {
            _ = try amountModule.validAmount()
            try addressModule.validateAddress()

            delegate?.onChange(isValid: feeModule.isValid)
        } catch {
            delegate?.onChange(isValid: false)
        }
    }

    private func syncAvailableBalance() {
        amountModule.set(availableBalance: interactor.availableBalance(gasPrice: feePriorityModule.feeRate))
    }

    private func syncFee() {
        feeModule.set(fee: interactor.fee(gasPrice: feePriorityModule.feeRate))
    }

    private func syncFeeDuration() {
        feeModule.set(duration: feePriorityModule.duration)
    }

}

extension SendEthereumHandler: ISendHandler {

    func onViewDidLoad() {
        amountModule.set(minimumRequiredBalance: interactor.minimumRequiredBalance)
        syncAvailableBalance()

        feeModule.set(availableFeeBalance: interactor.ethereumBalance)
        syncFee()
        syncFeeDuration()
    }

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew] {
        return [
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try addressModule.validAddress()),
            SendConfirmationFeeViewItem(primaryInfo: feeModule.primaryAmountInfo, secondaryInfo: feeModule.secondaryAmountInfo),
            SendConfirmationDurationViewItem(timeInterval: feePriorityModule.duration)
        ]
    }

    func sendSingle() throws -> Single<Void> {
        return interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress(), gasPrice: feePriorityModule.feeRate)
    }

}

extension SendEthereumHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncValidation()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendEthereumHandler: ISendAddressDelegate {

    func validate(address: String) throws {
        try interactor.validate(address: address)
    }

    func onUpdateAddress() {
        syncValidation()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

}

extension SendEthereumHandler: ISendFeeDelegate {

    var inputType: SendInputType {
        return amountModule.inputType
    }

}

extension SendEthereumHandler: ISendFeePriorityDelegate {

    func onUpdateFeePriority() {
        syncAvailableBalance()
        syncFee()
        syncValidation()
        syncFeeDuration()
    }

}
