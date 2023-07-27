import Foundation
import RxSwift
import RxCocoa
import MarketKit
import Combine
import HsExtensions

class CexWithdrawService {
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private let addressService: AddressService

    @PostPublished private(set) var proceedSendData: CexWithdrawModule.SendData? = nil
    @PostPublished private(set) var amountError: Error? = nil
    @PostPublished private(set) var selectedNetwork: CexWithdrawNetwork
    @PostPublished private(set) var fee: Decimal = 0
    private let availableBalanceSubject = PublishSubject<Decimal>()
    private let amountSubject = PublishSubject<Decimal>()

    let cexAsset: CexAsset
    let networks: [CexWithdrawNetwork]

    private var feeFromAmount: Bool
    private var _availableBalance: Decimal = 0 {
        didSet {
            availableBalanceSubject.onNext(_availableBalance)
        }
    }
    private(set) var amount: Decimal = 0 {
        didSet {
            amountSubject.onNext(amount)
        }
    }

    // error, errorObservable are for AddressService to show error on address input field if it is empty.
    // "Address Required" must be shown when "Next" button is clicked.
    private let errorRelay = BehaviorRelay<Error?>(value: nil)
    var error: Error? {
        didSet {
            errorRelay.accept(error)
        }
    }

    init(cexAsset: CexAsset, addressService: AddressService, selectedNetwork: CexWithdrawNetwork) {
        self.cexAsset = cexAsset
        self.addressService = addressService
        self.networks = cexAsset.withdrawNetworks
        self.selectedNetwork = selectedNetwork

        feeFromAmount = false
        syncAvailableBalance()
        addressService.customErrorService = self
        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in self?.error = nil }
    }

    private func syncFee() {
        fee = calculateFee(amount: amount, feeFromAmount: feeFromAmount)
        amountError = nil
    }

    private func syncAvailableBalance() {
        if feeFromAmount {
            _availableBalance = cexAsset.freeBalance
        } else {
            let fee = calculateFee(amount: cexAsset.freeBalance, feeFromAmount: true)
            _availableBalance = fee < cexAsset.freeBalance ? cexAsset.freeBalance - fee : 0
        }
    }

    private func validateAmount() throws {
        if amount > _availableBalance {
            throw AmountError.insufficientBalance
        }

        var maxAmount = selectedNetwork.maxAmount
        if maxAmount.isZero {
            maxAmount = Decimal.greatestFiniteMagnitude
        }

        if amount > maxAmount {
            throw AmountError.maxAmountViolated(coinAmount: "\(selectedNetwork.maxAmount.description) \(cexAsset.coinCode)")
        }

        if amount < selectedNetwork.minAmount {
            throw AmountError.minAmountViolated(coinAmount: "\(selectedNetwork.minAmount.description) \(cexAsset.coinCode)")
        }

        if feeFromAmount && amount < fee {
            throw AmountError.minAmountViolated(coinAmount: "\(fee.description) \(cexAsset.coinCode)")
        }
    }

    private func calculateFee(amount: Decimal, feeFromAmount: Bool) -> Decimal {
        var fee: Decimal = 0

        if feeFromAmount {
            fee = amount - (amount - selectedNetwork.fixedFee) / (1 + selectedNetwork.feePercent / 100)
        } else {
            fee = amount * selectedNetwork.feePercent / 100 + selectedNetwork.fixedFee
        }

        if fee < selectedNetwork.minFee {
            fee = selectedNetwork.minFee
        }

        return fee
    }

}

extension CexWithdrawService: IAvailableBalanceService {

    var availableBalance: DataStatus<Decimal> {
        .completed(_availableBalance)
    }

    var availableBalanceObservable: Observable<DataStatus<Decimal>> {
        availableBalanceSubject.asObserver().map { .completed($0) }
    }

}

extension CexWithdrawService: ICexAmountInputService {

    var balance: Decimal? {
        _availableBalance
    }

    var amountObservable: Observable<Decimal> {
        amountSubject.asObserver()
    }

    var balanceObservable: Observable<Decimal?> {
        availableBalanceSubject.asObserver().map { $0 }
    }

    func onChange(amount: Decimal) {
        self.amount = amount
        syncFee()
    }

}

extension CexWithdrawService: IErrorService {

    var errorObservable: Observable<Error?> {
        errorRelay.asObservable()
    }

}

extension CexWithdrawService {

    func setSelectNetwork(index: Int) {
        if let network = networks.at(index: index) {
            selectedNetwork = network
            network.blockchain.flatMap { addressService.change(blockchainType: $0.type) }
            syncAvailableBalance()
            syncFee()
        }
    }

    func set(feeFromAmount: Bool) {
        self.feeFromAmount = feeFromAmount
        syncAvailableBalance()
        syncFee()
    }

    func proceed() {
        do {
            try validateAmount()
        } catch {
            amountError = error
            return
        }

        switch addressService.state {
        case .empty: error = AddressError.addressRequired
        case .success(let address):
            proceedSendData = CexWithdrawModule.SendData(
                cexAsset: cexAsset,
                network: selectedNetwork,
                address: address.raw,
                amount: amount,
                feeFromAmount: feeFromAmount,
                fee: fee
            )
        default: ()
        }
    }

}

extension CexWithdrawService {

    enum AmountError: Error, LocalizedError {
        case insufficientBalance
        case maxAmountViolated(coinAmount: String)
        case minAmountViolated(coinAmount: String)

        public var errorDescription: String? {
            switch self {
            case .insufficientBalance: return "cex_withdraw.error.insufficient_funds".localized
            case .maxAmountViolated(let coinAmount): return "cex_withdraw.error.max_amount_violated".localized(coinAmount)
            case .minAmountViolated(let coinAmount): return "cex_withdraw.error.min_amount_violated".localized(coinAmount)
            }
        }
    }

    enum AddressError: Error, LocalizedError {
        case addressRequired

        public var errorDescription: String? {
            "cex_withdraw.address_required".localized
        }
    }

}
