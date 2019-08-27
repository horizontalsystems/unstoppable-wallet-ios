import Foundation
import RxSwift

class SendBinanceHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendBinanceInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule

    init(interactor: ISendBinanceInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
    }

    private func syncValidation() {
        do {
            _ = try amountModule.validAmount()
            _ = try addressModule.validAddress()

            delegate?.onChange(isValid: feeModule.isValid)
        } catch {
            delegate?.onChange(isValid: false)
        }
    }

}

extension SendBinanceHandler: ISendHandler {

    func onViewDidLoad() {
        amountModule.set(availableBalance: interactor.availableBalance)
        feeModule.set(fee: interactor.fee)
        feeModule.set(availableFeeBalance: interactor.availableBinanceBalance)
    }

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew] {
        return [
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try addressModule.validAddress()),
            SendConfirmationFeeViewItem(primaryInfo: feeModule.primaryAmountInfo, secondaryInfo: feeModule.secondaryAmountInfo),
        ]
    }

    func sendSingle() throws -> Single<Void> {
        return interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress(), memo: nil)
    }

}

extension SendBinanceHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncValidation()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendBinanceHandler: ISendAddressDelegate {

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

extension SendBinanceHandler: ISendFeeDelegate {

    var inputType: SendInputType {
        return amountModule.inputType
    }

}
