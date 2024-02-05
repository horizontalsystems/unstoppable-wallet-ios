import BitcoinCore
import Combine
import Foundation
import HsToolKit
import RxCocoa
import RxRelay
import RxSwift

protocol ISendInfoValueService: AnyObject {
    var unspentOutputs: [UnspentOutputInfo] { get }
    var customOutputs: [UnspentOutputInfo]? { get }
    var customOutputsUpdatedPublisher: AnyPublisher<Void, Never> { get }
    var sendInfoState: DataStatus<SendInfo> { get }
    var sendInfoStateObservable: Observable<DataStatus<SendInfo>> { get }
}

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
    private let queue = DispatchQueue(label: "\(AppConfig.label).send.bitcoin_adapter_service", qos: .userInitiated)

    private let feeRateService: FeeRateService
    private let amountInputService: IAmountInputService
    private let addressService: AddressService
    private let memoService: SendMemoInputService
    private let timeLockService: TimeLockService?
    private let btcBlockchainManager: BtcBlockchainManager
    private let adapter: ISendBitcoinAdapter

    let inputOutputOrderService: InputOutputOrderService
    let rbfService: RbfService

    let customOutputsUpdatedSubject = PassthroughSubject<Void, Never>()
    var customOutputs: [UnspentOutputInfo]? {
        didSet {
            if customOutputs != oldValue {
                sync()
                customOutputsUpdatedSubject.send()
            }
        }
    }

    // Outputs
    let feeRelay = BehaviorRelay<DataStatus<Decimal>>(value: .loading)
    var feeState: DataStatus<Decimal> = .loading {
        didSet {
            if !feeState.equalTo(oldValue) {
                feeRelay.accept(feeState)
            }
        }
    }

    let sendInfoRelay = BehaviorRelay<DataStatus<SendInfo>>(value: .loading)
    var sendInfoState: DataStatus<SendInfo> = .loading {
        didSet {
            feeState = sendInfoState.map(\.fee)
            sendInfoRelay.accept(sendInfoState)
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
    var maximumSendAmount: Decimal? {
        didSet {
            if maximumSendAmount != oldValue {
                maximumSendAmountRelay.accept(maximumSendAmount)
            }
        }
    }

    init(feeRateService: FeeRateService, amountInputService: IAmountInputService, addressService: AddressService, memoService: SendMemoInputService,
         inputOutputOrderService: InputOutputOrderService, rbfService: RbfService, timeLockService: TimeLockService?, btcBlockchainManager: BtcBlockchainManager, adapter: ISendBitcoinAdapter)
    {
        self.feeRateService = feeRateService
        self.amountInputService = amountInputService
        self.addressService = addressService
        self.memoService = memoService
        self.timeLockService = timeLockService
        self.inputOutputOrderService = inputOutputOrderService
        self.rbfService = rbfService
        self.btcBlockchainManager = btcBlockchainManager
        self.adapter = adapter

        subscribe(disposeBag, amountInputService.amountObservable) { [weak self] _ in
            self?.sync(updatedFrom: .amount)
        }
        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in
            self?.sync(updatedFrom: .address)
        }
        subscribe(disposeBag, memoService.memoObservable) { [weak self] _ in
            self?.sync(updatedFrom: .memo)
        }

        if let timeLockService {
            subscribe(disposeBag, timeLockService.pluginDataObservable) { [weak self] _ in
                self?.sync(updatedFrom: .pluginData)
            }
        }

        subscribe(disposeBag, feeRateService.statusObservable) { [weak self] in
            self?.sync(feeRate: $0)
        }
        sync(feeRate: feeRateService.status)

        minimumSendAmount = adapter.minimumSendAmount(address: addressService.state.address?.raw)
        maximumSendAmount = adapter.maximumSendAmount(pluginData: pluginData)
    }

    private func sync(feeRate: DataStatus<Int>? = nil, updatedFrom: UpdatedField = .feeRate) {
        let feeRateStatus = feeRate ?? feeRateService.status
        let amount = amountInputService.amount
        var feeRate = 0

        switch feeRateStatus {
        case .loading:
            guard !amount.isZero else { // force update fee for bitcoin, when clear amount to zero value
                sendInfoState = .completed(SendInfo.empty)
                return
            }

            sendInfoState = .loading
        case let .failed(error):
            sendInfoState = .failed(error)
        case let .completed(_feeRate):
            feeRate = _feeRate
        }

        update(feeRate: feeRate, amount: amount, address: addressService.state.address?.raw, pluginData: pluginData, updatedFrom: updatedFrom)
    }

    private func update(feeRate: Int, amount: Decimal, address: String?, pluginData: [UInt8: IBitcoinPluginData], updatedFrom: UpdatedField) {
        let memo = memoService.memo
        queue.async { [weak self] in
            do {
                if let sendInfo = try self?.adapter
                    .sendInfo(amount: amount, feeRate: feeRate, address: address, memo: memo, unspentOutputs: self?.customOutputs, pluginData: pluginData)
                {
                    self?.sendInfoState = .completed(sendInfo)
                }
            } catch {
                self?.sendInfoState = .failed(error)
            }

            if updatedFrom != .amount,
               let availableBalance = self?.adapter.availableBalance(feeRate: feeRate, address: address, memo: memo, unspentOutputs: self?.customOutputs, pluginData: pluginData)
            {
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

    private var pluginData: [UInt8: IBitcoinPluginData] {
        timeLockService?.pluginData ?? [:]
    }
}

extension SendBitcoinAdapterService: ISendInfoValueService, ISendXFeeValueService, IAvailableBalanceService, ISendXSendAmountBoundsService {
    var unspentOutputs: [UnspentOutputInfo] {
        adapter.unspentOutputs
    }

    var customOutputsUpdatedPublisher: AnyPublisher<Void, Never> {
        customOutputsUpdatedSubject.eraseToAnyPublisher()
    }

    var feeStateObservable: Observable<DataStatus<Decimal>> {
        feeRelay.asObservable()
    }

    var sendInfoStateObservable: Observable<DataStatus<SendInfo>> {
        sendInfoRelay.asObservable()
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
        try adapter.validate(address: address, pluginData: pluginData)
    }
}

extension SendBitcoinAdapterService: ISendService {
    func sendSingle(logger: Logger) -> Single<Void> {
        let address: Address
        switch addressService.state {
        case let .success(sendAddress): address = sendAddress
        case let .fetchError(error): return Single.error(error)
        default: return Single.error(AppError.addressInvalid)
        }

        guard case let .completed(feeRate) = feeRateService.status else {
            return Single.error(SendTransactionError.noFee)
        }

        guard !amountInputService.amount.isZero else {
            return Single.error(SendTransactionError.wrongAmount)
        }

        let sortMode = btcBlockchainManager.transactionSortMode(blockchainType: adapter.blockchainType)
        let rbfEnabled = btcBlockchainManager.transactionRbfEnabled(blockchainType: adapter.blockchainType)
        return adapter.sendSingle(
            amount: amountInputService.amount,
            address: address.raw,
            memo: memoService.memo,
            feeRate: feeRate,
            unspentOutputs: customOutputs,
            pluginData: pluginData,
            sortMode: sortMode,
            rbfEnabled: rbfEnabled,
            logger: logger
        )
    }
}

extension SendBitcoinAdapterService {
    private enum UpdatedField: String {
        case amount, address, memo, pluginData, feeRate
    }
}
