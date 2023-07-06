import Foundation
import RxSwift
import MarketKit
import Combine
import HsExtensions

class CexWithdrawService {
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    let cexAsset: CexAsset
    let networkService: CexWithdrawNetworkSelectService
    private let addressService: AddressService

    @PostPublished private(set) var state: State = .notReady
    @PostPublished private(set) var amountError: Error? = nil

    private var validAmount: Decimal? = nil

    init(cexAsset: CexAsset, networkService: CexWithdrawNetworkSelectService, addressService: AddressService) {
        self.cexAsset = cexAsset
        self.networkService = networkService
        self.addressService = addressService

        subscribe(&cancellables, networkService.$selectedNetwork) { [weak self] in
            guard let blockchainType = $0?.blockchain?.type else {
                return
            }

            self?.addressService.change(blockchainType: blockchainType)
        }

        addressService.stateObservable
            .subscribe { [weak self] _ in self?.syncState() }
            .disposed(by: disposeBag)
    }

    private func syncState() {
        if amountError == nil, case let .success(address) = addressService.state, let amount = validAmount {
            state = .ready(sendData: CexWithdrawModule.SendData(
                cexAsset: cexAsset, network: networkService.selectedNetwork, address: address.raw, amount: amount))
        } else {
            state = .notReady
        }
    }

}

extension CexWithdrawService: IAvailableBalanceService {

    var availableBalance: DataStatus<Decimal> {
        .completed(cexAsset.freeBalance)
    }

    var availableBalanceObservable: Observable<DataStatus<Decimal>> {
        Observable.just(.completed(cexAsset.freeBalance))
    }

}

extension CexWithdrawService: ICexAmountInputService {

    var amount: Decimal {
        0
    }

    var balance: Decimal? {
        cexAsset.freeBalance
    }

    var amountObservable: Observable<Decimal> {
        .empty()
    }

    var balanceObservable: Observable<Decimal?> {
        .just(cexAsset.freeBalance)
    }

    func onChange(amount: Decimal) {
        if amount > 0 {
            do {
                if amount > cexAsset.freeBalance {
                    throw AmountError.insufficientBalance
                }

                validAmount = amount
            } catch {
                validAmount = nil
                amountError = error
            }
        } else {
            validAmount = nil
            amountError = nil
        }

        syncState()
    }

}

extension CexWithdrawService {

    enum State {
        case ready(sendData: CexWithdrawModule.SendData)
        case notReady
    }

    enum AmountError: Error {
        case insufficientBalance
    }

}
