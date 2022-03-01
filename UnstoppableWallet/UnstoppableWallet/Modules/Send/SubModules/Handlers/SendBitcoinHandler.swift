import Foundation
import RxSwift
import HsToolKit

class SendBitcoinHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendBitcoinInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule
    private let feePriorityModule: ISendFeePriorityModule
    private let hodlerModule: ISendHodlerModule?
    private let bitcoinAddressParser: BitcoinAddressParserItem

    private var pluginData = [UInt8: IBitcoinPluginData]()

    init(interactor: ISendBitcoinInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule,
         feeModule: ISendFeeModule, feePriorityModule: ISendFeePriorityModule, hodlerModule: ISendHodlerModule?, bitcoinAddressParser: BitcoinAddressParserItem) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
        self.feePriorityModule = feePriorityModule
        self.hodlerModule = hodlerModule
        self.bitcoinAddressParser = bitcoinAddressParser
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

        delegate?.onChange(isValid: amountError == nil && addressError == nil, amountError: amountError, addressError: addressError)
    }

    private func syncMaximumAmount() {
        interactor.fetchMaximumAmount(pluginData: pluginData)
    }

    private func syncMinimumAmount() {
        interactor.fetchMinimumAmount(address: addressModule.currentAddress?.raw)
    }

    private func syncState() {
        let loading = feePriorityModule.feeRateState.isLoading

        amountModule.set(loading: loading)

        guard !loading else {
            return
        }

        if case let .error(error) = feePriorityModule.feeRateState {
            feeModule.set(fee: 0)
            feeModule.set(externalError: error)
        } else if case let .value(feeRateValue) = feePriorityModule.feeRateState {
            interactor.fetchAvailableBalance(feeRate: feeRateValue, address: addressModule.currentAddress?.raw, pluginData: pluginData)

            feeModule.set(externalError: nil)
            interactor.fetchFee(amount: amountModule.currentAmount, feeRate: feeRateValue, address: addressModule.currentAddress?.raw, pluginData: pluginData)
        }
    }

}

extension SendBitcoinHandler: ISendHandler {

    func onViewDidLoad() {
        feePriorityModule.set(balance: interactor.balance)
        feePriorityModule.fetchFeeRate()

        syncState()
        syncMinimumAmount()
    }

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew] {
        var items: [ISendConfirmationViewItemNew] = [
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try addressModule.validAddress())
        ]
        items.append(SendConfirmationFeeViewItem(primaryInfo: feeModule.primaryAmountInfo, secondaryInfo: feeModule.secondaryAmountInfo))
        if let lockValue = hodlerModule?.lockValue {
            items.append(SendConfirmationLockUntilViewItem(lockValue: lockValue))
        }
        return items
    }

    func sync() {
        if feePriorityModule.feeRateState.isError {
            feePriorityModule.fetchFeeRate()
            syncState()
            syncValidation()
        }
    }

    func sync(rateValue: Decimal?) {
        feePriorityModule.set(xRate: rateValue)
        amountModule.set(rateValue: rateValue)
    }

    func sync(inputType: SendInputType) {
        amountModule.set(inputType: inputType)
        feeModule.update(inputType: inputType)
    }

    func sendSingle(logger: Logger) throws -> Single<Void> {
        guard let feeRate = feePriorityModule.feeRate else {
            throw SendTransactionError.noFee
        }
        return interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress().raw, feeRate: feeRate, pluginData: pluginData, logger: logger)
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
        feePriorityModule.set(amountInfo: amountModule.sendAmountInfo)

        syncState()
        syncValidation()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendBitcoinHandler: ISendAddressDelegate {

    func onUpdateAddress() {
        syncMinimumAmount()
        syncState()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

}

extension SendBitcoinHandler: ISendFeePriorityDelegate {

    func onUpdateFeePriority() {
        syncState()
    }

}

extension SendBitcoinHandler: ISendHodlerDelegate {

    func onUpdateLockTimeInterval() {
        guard let hodlerModule = hodlerModule else {
            return
        }

        pluginData = hodlerModule.pluginData
        bitcoinAddressParser.pluginData = pluginData

        syncValidation()
        syncMaximumAmount()
        syncState()
    }

}
