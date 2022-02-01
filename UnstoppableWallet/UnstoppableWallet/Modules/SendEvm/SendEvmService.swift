import Foundation
import MarketKit
import RxSwift
import RxRelay
import EthereumKit
import BigInt

class SendEvmService {
    let sendPlatformCoin: PlatformCoin
    private let disposeBag = DisposeBag()
    private let adapter: ISendEthereumAdapter
    private let addressService: AddressService

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var evmAmount: BigUInt?
    private var addressData: AddressData?

    private let amountCautionRelay = PublishRelay<(error: Error?, warning: AmountWarning?)>()
    private var amountCaution: (error: Error?, warning: AmountWarning?) = (error: nil, warning: nil) {
        didSet {
            amountCautionRelay.accept(amountCaution)
        }
    }

    private let addressErrorRelay = PublishRelay<Error?>()
    private var addressError: Error? {
        didSet {
            addressErrorRelay.accept(addressError)
        }
    }

    init(platformCoin: PlatformCoin, adapter: ISendEthereumAdapter, addressService: AddressService) {
        sendPlatformCoin = platformCoin
        self.adapter = adapter
        self.addressService = addressService

        subscribe(disposeBag, addressService.stateObservable) { [weak self] in self?.sync(addressState: $0) }
    }

    private func sync(addressState: AddressService.State) {
        switch addressState {
        case .success(let address):
            do {
                addressData = AddressData(evmAddress: try EthereumKit.Address(hex: address.raw), domain: address.domain)
            } catch {
                addressData = nil
            }
        default: addressData = nil
        }

        syncState()
    }

    private func syncState() {
        if amountCaution.error == nil, case .success = addressService.state, let evmAmount = evmAmount, let addressData = addressData {
            let transactionData = adapter.transactionData(amount: evmAmount, address: addressData.evmAddress)
            let sendInfo = SendEvmData.SendInfo(domain: addressData.domain)

            let sendData = SendEvmData(transactionData: transactionData, additionalInfo: .send(info: sendInfo), warnings: [])
            state = .ready(sendData: sendData)
        } else {
            state = .notReady
        }
    }

    private func validEvmAmount(amount: Decimal) throws -> BigUInt {
        guard let evmAmount = BigUInt(amount.roundedString(decimal: sendPlatformCoin.decimals)) else {
            throw AmountError.invalidDecimal
        }

        guard amount <= adapter.balanceData.balance else {
            throw AmountError.insufficientBalance
        }

        return evmAmount
    }

}

extension SendEvmService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var amountCautionObservable: Observable<(error: Error?, warning: AmountWarning?)> {
        amountCautionRelay.asObservable()
    }

}

extension SendEvmService: IAvailableBalanceService {

    var availableBalance: Decimal {
        adapter.balanceData.balance
    }

}

extension SendEvmService: IAmountInputService {

    var amount: Decimal {
        0
    }

    var platformCoin: PlatformCoin? {
        sendPlatformCoin
    }

    var balance: Decimal? {
        adapter.balanceData.balance
    }

    var amountObservable: Observable<Decimal> {
        .empty()
    }

    var platformCoinObservable: Observable<PlatformCoin?> {
        .empty()
    }

    func onChange(amount: Decimal) {
        if amount > 0 {
            do {
                evmAmount = try validEvmAmount(amount: amount)

                var amountWarning: AmountWarning? = nil
                if amount.isEqual(to: adapter.balanceData.balance) {
                    switch sendPlatformCoin.coinType {
                    case .binanceSmartChain, .ethereum: amountWarning = AmountWarning.coinNeededForFee
                    default: ()
                    }
                }

                amountCaution = (error: nil, warning: amountWarning)
            } catch {
                evmAmount = nil
                amountCaution = (error: error, warning: nil)
            }
        } else {
            evmAmount = nil
            amountCaution = (error: nil, warning: nil)
        }

        syncState()
    }

}

extension SendEvmService {

    enum State {
        case ready(sendData: SendEvmData)
        case notReady
    }

    enum AmountError: Error {
        case invalidDecimal
        case insufficientBalance
    }

    enum AmountWarning {
        case coinNeededForFee
    }

    private struct AddressData {
        let evmAddress: EthereumKit.Address
        let domain: String?
    }

}
