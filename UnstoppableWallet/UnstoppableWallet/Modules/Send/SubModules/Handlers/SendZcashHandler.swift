import Foundation
import RxSwift
import HsToolKit

class SendZcashHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendZcashInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let memoModule: ISendMemoModule
    private let feeModule: ISendFeeModule

    init(interactor: ISendZcashInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule, memoModule: ISendMemoModule, feeModule: ISendFeeModule) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.memoModule = memoModule
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
            try addressModule.validateAddress()
        } catch {
            addressError = error
        }

        delegate?.onChange(isValid: amountError == nil && addressError == nil && feeModule.isValid, amountError: amountError, addressError: addressError)
    }

    private func syncAvailableBalance() {
        amountModule.set(availableBalance: interactor.availableBalance)
    }

}

extension SendZcashHandler: ISendHandler {

    func onViewDidLoad() {
        syncAvailableBalance()
        feeModule.set(fee: interactor.fee)
    }

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew] {
        var viewItems: [ISendConfirmationViewItemNew] = [
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try addressModule.validAddress())
        ]

        if let memo = memoModule.memo {
            viewItems.append(SendConfirmationMemoViewItem(memo: memo))
        }

        viewItems.append(SendConfirmationFeeViewItem(primaryInfo: feeModule.primaryAmountInfo, secondaryInfo: feeModule.secondaryAmountInfo))

        return viewItems
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
        interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress().raw, memo: memoModule.memo)
                .do(onSubscribe: { logger.debug("Sending to ISendZcashInteractor", save: true) })
    }

}

extension SendZcashHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncValidation()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendZcashHandler: ISendAddressDelegate {

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
