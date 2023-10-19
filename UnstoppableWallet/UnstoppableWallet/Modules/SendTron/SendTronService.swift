import Foundation
import MarketKit
import RxSwift
import RxRelay
import TronKit
import BigInt
import HsExtensions

class SendTronService {
    let sendToken: Token
    let mode: SendBaseService.Mode

    private let disposeBag = DisposeBag()
    private let adapter: ISendTronAdapter
    private let addressService: AddressService

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var tronAmount: BigUInt?
    private var addressData: AddressData?

    private let amountCautionRelay = PublishRelay<(error: Error?, warning: AmountWarning?)>()
    private var amountCaution: (error: Error?, warning: AmountWarning?) = (error: nil, warning: nil) {
        didSet {
            amountCautionRelay.accept(amountCaution)
        }
    }

    private let addressErrorRelay = PublishRelay<Error?>()
    private var addressError: Error? = nil {
        didSet {
            addressErrorRelay.accept(addressError)
        }
    }

    private let activeAddressRelay = PublishRelay<Bool>()

    init(token: Token, mode: SendBaseService.Mode, adapter: ISendTronAdapter, addressService: AddressService) {
        sendToken = token
        self.mode = mode
        self.adapter = adapter
        self.addressService = addressService

        switch mode {
        case .predefined(let address): addressService.set(text: address)
        case .send: ()
        }

        subscribe(disposeBag, addressService.stateObservable) { [weak self] in self?.sync(addressState: $0) }
    }

    private func sync(addressState: AddressService.State) {
        switch addressState {
            case .success(let address):
                do {
                    addressData = AddressData(tronAddress: try TronKit.Address(address: address.raw), domain: address.domain)
                } catch {
                    addressData = nil
                }
            default: addressData = nil
        }

        syncState()
    }

    private func syncState() {
        if amountCaution.error == nil, case .success = addressService.state, let tronAmount = tronAmount, let addressData = addressData {
            let contract = adapter.contract(amount: tronAmount, address: addressData.tronAddress)
            state = .ready(contract: contract)
        } else {
            state = .notReady
        }
    }

    private func validTronAmount(amount: Decimal) throws -> BigUInt {
        guard let tronAmount = BigUInt(amount.hs.roundedString(decimal: sendToken.decimals)) else {
            throw AmountError.invalidDecimal
        }

        guard amount <= adapter.balanceData.available else {
            throw AmountError.insufficientBalance
        }

        return tronAmount
    }

}

extension SendTronService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var amountCautionObservable: Observable<(error: Error?, warning: AmountWarning?)> {
        amountCautionRelay.asObservable()
    }

    var addressErrorObservable: Observable<Error?> {
        addressErrorRelay.asObservable()
    }

    var activeAddressObservable: Observable<Bool> {
        activeAddressRelay.asObservable()
    }

}

extension SendTronService: IAvailableBalanceService {

    var availableBalance: DataStatus<Decimal> {
        .completed(adapter.balanceData.available)
    }

    var availableBalanceObservable: Observable<DataStatus<Decimal>> {
        Observable.just(availableBalance)
    }

}

extension SendTronService: IAmountInputService {

    var amount: Decimal {
        0
    }

    var token: Token? {
        sendToken
    }

    var balance: Decimal? {
        adapter.balanceData.available
    }

    var amountObservable: Observable<Decimal> {
        .empty()
    }

    var tokenObservable: Observable<Token?> {
        .empty()
    }

    var balanceObservable: Observable<Decimal?> {
        .just(adapter.balanceData.available)
    }

    func onChange(amount: Decimal) {
        if amount > 0 {
            do {
                tronAmount = try validTronAmount(amount: amount)

                var amountWarning: AmountWarning? = nil
                if amount.isEqual(to: adapter.balanceData.available) {
                    switch sendToken.type {
                        case .native: amountWarning = AmountWarning.coinNeededForFee
                        default: ()
                    }
                }

                amountCaution = (error: nil, warning: amountWarning)
            } catch {
                tronAmount = nil
                amountCaution = (error: error, warning: nil)
            }
        } else {
            tronAmount = nil
            amountCaution = (error: nil, warning: nil)
        }

        syncState()
    }

    func sync(address: String) {
        guard let tronAddress = try? TronKit.Address(address: address) else {
            return
        }

        guard tronAddress != adapter.tronKitWrapper.tronKit.receiveAddress else {
            state = .notReady
            addressError = AddressError.ownAddress
            return
        }

        Single<Bool>
            .create { [weak self] observer in
                let task = Task { [weak self] in
                    let active = await self?.adapter.accountActive(address: tronAddress) ?? false
                    observer(.success(active))
                }

                return Disposables.create {
                    task.cancel()
                }
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onSuccess: { [weak self] active in
                self?.activeAddressRelay.accept(active)
            })
            .disposed(by: disposeBag)
    }

}

extension SendTronService {

    enum State {
        case ready(contract: TronKit.Contract)
        case notReady
    }

    enum AmountError: Error {
        case invalidDecimal
        case insufficientBalance
    }

    enum AddressError: Error {
        case ownAddress
    }

    enum AmountWarning {
        case coinNeededForFee
    }

    private struct AddressData {
        let tronAddress: TronKit.Address
        let domain: String?
    }

}
