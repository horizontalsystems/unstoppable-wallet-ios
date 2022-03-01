import Foundation
import RxSwift
import HsToolKit

class SendDashHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendDashInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule

    init(interactor: ISendDashInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
    }

    private func syncValidation() {
        var amountError: Error?
        var addressError: Error?

        do {
            _ = try amountModule.validAmount()
        } catch {
            amountError = error
        }

        do {
            _ = try addressModule.validAddress()
        } catch {
            addressError = error
        }

        delegate?.onChange(isValid: amountError == nil &&  addressError == nil, amountError: amountError, addressError: addressError)
    }

    private func syncAvailableBalance() {
        interactor.fetchAvailableBalance(address: addressModule.currentAddress?.raw)
    }

    private func syncMinimumAmount() {
        interactor.fetchMinimumAmount(address: addressModule.currentAddress?.raw)
    }

    private func syncFee() {
        interactor.fetchFee(amount: amountModule.currentAmount, address: addressModule.currentAddress?.raw)
    }

}

extension SendDashHandler: ISendHandler {

    func onViewDidLoad() {
        syncAvailableBalance()
        syncMinimumAmount()
    }

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew] {
        [
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try addressModule.validAddress()),
            SendConfirmationFeeViewItem(primaryInfo: feeModule.primaryAmountInfo, secondaryInfo: feeModule.secondaryAmountInfo),
        ]
    }

    func sync() {
    }

    func sync(rateValue: Decimal?) {
        amountModule.set(rateValue: rateValue)
    }

    func sync(inputType: SendInputType) {
        amountModule.set(inputType: inputType)
        feeModule.update(inputType: inputType)
    }

    func sendSingle(logger: Logger) throws -> Single<Void> {
        interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress().raw, logger: logger)
    }

}

extension SendDashHandler: ISendDashInteractorDelegate {

    func didFetch(availableBalance: Decimal) {
        amountModule.set(availableBalance: availableBalance)
        syncValidation()
    }

    func didFetch(minimumAmount: Decimal) {
        amountModule.set(minimumAmount: minimumAmount)
        syncValidation()
    }

    func didFetch(fee: Decimal) {
        feeModule.set(fee: fee)
    }

}

extension SendDashHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncFee()
        syncValidation()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendDashHandler: ISendAddressDelegate {

    func onUpdateAddress() {
        syncAvailableBalance()
        syncFee()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

}
