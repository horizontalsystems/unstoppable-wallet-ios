import Foundation
import RxSwift

class SendBitcoinHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendBitcoinInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule
    private let feePriorityModule: ISendFeePriorityModule

    init(interactor: ISendBitcoinInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule, feePriorityModule: ISendFeePriorityModule) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
        self.feePriorityModule = feePriorityModule
    }

    private func syncValidation() {
        do {
            _ = try amountModule.validAmount()
            _ = try addressModule.validAddress()

            delegate?.onChange(isValid: true)
        } catch {
            delegate?.onChange(isValid: false)
        }
    }

    private func syncAvailableBalance() {
        interactor.fetchAvailableBalance(feeRate: feePriorityModule.feeRate, address: addressModule.currentAddress)
    }

    private func syncFee() {
        interactor.fetchFee(amount: amountModule.currentAmount, feeRate: feePriorityModule.feeRate, address: addressModule.currentAddress)
    }

    private func syncFeeDuration() {
        feeModule.set(duration: feePriorityModule.duration)
    }

}

extension SendBitcoinHandler: ISendHandler {

    func onViewDidLoad() {
        syncAvailableBalance()
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
        return interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress(), feeRate: feePriorityModule.feeRate)
    }

}

extension SendBitcoinHandler: ISendBitcoinInteractorDelegate {

    func didFetch(availableBalance: Decimal) {
        amountModule.set(availableBalance: availableBalance)
        syncValidation()
    }

    func didFetch(fee: Decimal) {
        feeModule.set(fee: fee)
    }

}

extension SendBitcoinHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncFee()
        syncValidation()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendBitcoinHandler: ISendAddressDelegate {

    func validate(address: String) throws {
        try interactor.validate(address: address)
    }

    func onUpdateAddress() {
        syncAvailableBalance()
        syncFee()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

}

extension SendBitcoinHandler: ISendFeeDelegate {

    var inputType: SendInputType {
        return amountModule.inputType
    }

}

extension SendBitcoinHandler: ISendFeePriorityDelegate {

    func onUpdateFeePriority() {
        syncAvailableBalance()
        syncFee()
        syncFeeDuration()
    }

}
