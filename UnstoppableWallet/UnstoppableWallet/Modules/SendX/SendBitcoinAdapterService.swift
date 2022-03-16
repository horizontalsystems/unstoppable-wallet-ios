import Foundation
import RxSwift
import RxCocoa
import RxRelay
import HsToolKit

protocol ISendXFeeValueService: AnyObject {
    var feeState: DataStatus<Decimal> { get }
    var feeStateObservable: Observable<DataStatus<Decimal>> { get }
}

protocol ISendXSendAmountBoundsService: AnyObject {
    var minimumSendAmount: Decimal { get }
    var minimumSendAmountObservable: Observable<Decimal> { get }
    var maximumSendAmount: Decimal? { get }
    var maximumSendAmountObservable: Observable<Decimal?> { get }
}

protocol ISendService {
    func sendSingle(logger: Logger) -> Single<Void>
}

class SendBitcoinAdapterService {
    private let disposeBag = DisposeBag()
    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.send.bitcoin_adapter_service", qos: .userInitiated)

    private let feeRateService: SendXFeeRateService
    private let amountInputService: IAmountInputService
    private let addressService: AddressService
    private let timeLockService: SendXTimeLockService
    private let btcBlockchainManager: BtcBlockchainManager
    private let bitcoinAddressParserItem: BitcoinAddressParserItem

    private let adapter: ISendBitcoinAdapter

    // Outputs
    let feeStateRelay = BehaviorRelay<DataStatus<Decimal>>(value: .loading)
    var feeState: DataStatus<Decimal> = .loading {
        didSet {
            if !feeState.equalTo(oldValue) {
                feeStateRelay.accept(feeState)
            }
        }
    }

    let availableBalanceRelay = BehaviorRelay<DataStatus<Decimal>>(value: .loading)
    var availableBalance: DataStatus<Decimal> = .loading {
        didSet {
            if !availableBalance.equalTo(oldValue) {
                availableBalanceRelay.accept(availableBalance)
            }
        }
    }

    let minimumSendAmountRelay = BehaviorRelay<Decimal>(value: 0)
    var minimumSendAmount: Decimal = 0 {
        didSet {
            if minimumSendAmount != oldValue {
                minimumSendAmountRelay.accept(minimumSendAmount)
            }
        }
    }

    let maximumSendAmountRelay = BehaviorRelay<Decimal?>(value: nil)
    var maximumSendAmount: Decimal? = nil {
        didSet {
            if maximumSendAmount != oldValue {
                maximumSendAmountRelay.accept(maximumSendAmount)
            }
        }
    }

    init(feeRateService: SendXFeeRateService, amountInputService: IAmountInputService, addressService: AddressService, timeLockService: SendXTimeLockService, btcBlockchainManager: BtcBlockchainManager, adapter: ISendBitcoinAdapter, bitcoinAddressParserItem: BitcoinAddressParserItem) {
        self.feeRateService = feeRateService
        self.amountInputService = amountInputService
        self.addressService = addressService
        self.timeLockService = timeLockService
        self.btcBlockchainManager = btcBlockchainManager
        self.adapter = adapter
        self.bitcoinAddressParserItem = bitcoinAddressParserItem

        subscribe(disposeBag, amountInputService.amountObservable) { [weak self] _ in
            self?.sync(updatedFrom: .amount)
        }
        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in
            self?.sync(updatedFrom: .address)
        }
        subscribe(disposeBag, timeLockService.pluginDataObservable) { [weak self] in
            self?.bitcoinAddressParserItem.pluginData = $0
            self?.sync(updatedFrom: .pluginData)
        }
        subscribe(disposeBag, feeRateService.feeRateObservable) { [weak self] in
            self?.sync(feeRate: $0)
        }

        minimumSendAmount = adapter.minimumSendAmount(address: addressService.state.address?.raw)
        maximumSendAmount = adapter.maximumSendAmount(pluginData: timeLockService.pluginData)
    }

    private func sync(feeRate: DataStatus<Int>? = nil, updatedFrom: UpdatedField = .feeRate) {
        let feeRate = feeRate ?? feeRateService.feeRate
        let amount = amountInputService.amount

        switch feeRate {
        case .loading:
            guard !amount.isZero else {      // force update fee for bitcoin, when clear amount to zero value
                feeState = .completed(0)
                return
            }

            feeState = .loading
        case .failed(let error):
            feeState = .failed(error)
        case .completed(let feeRate):
            update(feeRate: feeRate, amount: amount, address: addressService.state.address?.raw, pluginData: timeLockService.pluginData, updatedFrom: updatedFrom)
        }
    }

    private func update(feeRate: Int, amount: Decimal, address: String?, pluginData: [UInt8: IBitcoinPluginData], updatedFrom: UpdatedField) {
        queue.async { [weak self] in
            if let fee = self?.adapter.fee(amount: amount, feeRate: feeRate, address: address, pluginData: pluginData) {
                self?.feeState = .completed(fee)
            }
            if updatedFrom != .amount,
               let availableBalance = self?.adapter.availableBalance(feeRate: feeRate, address: address, pluginData: pluginData) {
                self?.availableBalance = .completed(availableBalance)
            }
            if updatedFrom == .pluginData {
                self?.maximumSendAmount = self?.adapter.maximumSendAmount(pluginData: pluginData)
            }
            if updatedFrom == .address {
                self?.minimumSendAmount = self?.adapter.minimumSendAmount(address: address) ?? 0
            }
        }
    }

}

extension SendBitcoinAdapterService: ISendXFeeValueService, IAvailableBalanceService, ISendXSendAmountBoundsService {

    var feeStateObservable: Observable<DataStatus<Decimal>> {
        feeStateRelay.asObservable()
    }

    var availableBalanceObservable: Observable<DataStatus<Decimal>> {
        availableBalanceRelay.asObservable()
    }

    var minimumSendAmountObservable: Observable<Decimal> {
        minimumSendAmountRelay.asObservable()
    }

    var maximumSendAmountObservable: Observable<Decimal?> {
        maximumSendAmountRelay.asObservable()
    }

    func validate(address: String) throws {
        try adapter.validate(address: address, pluginData: timeLockService.pluginData)
    }

}

extension SendBitcoinAdapterService: ISendService {

    func sendSingle(logger: Logger) -> Single<Void> {
        guard let address = addressService.state.address?.raw, // todo: check errors
              case let .completed(feeRate) = feeRateService.feeRate else {
            return Single.error(AppError.addressInvalid)
        }

        let sortMode = btcBlockchainManager.transactionSortMode(blockchain: adapter.blockchain)
        return adapter.sendSingle(amount: amountInputService.amount, address: address, feeRate: feeRate, pluginData: timeLockService.pluginData, sortMode: sortMode, logger: logger)
    }

}

extension SendBitcoinAdapterService {

    private enum UpdatedField: String {
        case amount, address, pluginData, feeRate
    }

}
