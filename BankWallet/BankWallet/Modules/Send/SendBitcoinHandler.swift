import Foundation
import RxSwift

class SendBitcoinHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendBitcoinInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule
    private let feePriorityModule: ISendFeePriorityModule
    private let hodlerModule: ISendHodlerModule?

    private var pluginData = [UInt8: IBitcoinPluginData]()

    init(interactor: ISendBitcoinInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule,
         feeModule: ISendFeeModule, feePriorityModule: ISendFeePriorityModule, hodlerModule: ISendHodlerModule?) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
        self.feePriorityModule = feePriorityModule
        self.hodlerModule = hodlerModule
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
        interactor.fetchAvailableBalance(feeRate: feePriorityModule.feeRate, address: addressModule.currentAddress, pluginData: pluginData)
    }

    private func syncMaximumAmount() {
        interactor.fetchMaximumAmount(pluginData: pluginData)
    }

    private func syncMinimumAmount() {
        interactor.fetchMinimumAmount(address: addressModule.currentAddress)
    }

    private func syncFee() {
        interactor.fetchFee(amount: amountModule.currentAmount, feeRate: feePriorityModule.feeRate, address: addressModule.currentAddress, pluginData: pluginData)
    }

    private func syncFeeDuration() {
        feeModule.set(duration: feePriorityModule.duration)
    }

}

extension SendBitcoinHandler: ISendHandler {

    func onViewDidLoad() {
        syncAvailableBalance()
        syncMinimumAmount()
        syncFeeDuration()
    }

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew] {
        [
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try addressModule.validAddress()),
            SendConfirmationFeeViewItem(primaryInfo: feeModule.primaryAmountInfo, secondaryInfo: feeModule.secondaryAmountInfo),
            SendConfirmationDurationViewItem(timeInterval: feePriorityModule.duration)
        ]
    }

    func sendSingle() throws -> Single<Void> {
        interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress(), feeRate: feePriorityModule.feeRate, pluginData: pluginData)
    }

}

extension SendBitcoinHandler: ISendBitcoinInteractorDelegate {

    func didFetch(availableBalance: Decimal) {
        amountModule.set(availableBalance: availableBalance)
        syncValidation()
    }
    
    func didFetch(maximumAmount: Decimal?) {
        amountModule.set(maximumAmount: maximumAmount)
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
        syncMinimumAmount()
        syncFee()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

}

extension SendBitcoinHandler: ISendFeeDelegate {

    var inputType: SendInputType {
        amountModule.inputType
    }

}

extension SendBitcoinHandler: ISendFeePriorityDelegate {

    func onUpdateFeePriority() {
        syncAvailableBalance()
        syncFee()
        syncFeeDuration()
    }

}

extension SendBitcoinHandler: ISendHodlerDelegate {

    func onUpdateLockTimeInterval() {
        guard let hodlerModule = hodlerModule else {
            return
        }

        pluginData = hodlerModule.pluginData
        syncAvailableBalance()
        syncMaximumAmount()
        syncFee()
    }

}
