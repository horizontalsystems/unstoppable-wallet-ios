import Foundation
import CoinKit
import RxSwift
import RxRelay
import EthereumKit
import BigInt

class SendEvmService {
    let sendCoin: Coin
    private let adapter: ISendEthereumAdapter

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var evmAmount: BigUInt?
    private var addressData: AddressData?

    private let amountErrorRelay = PublishRelay<Error?>()
    private var amountError: Error? {
        didSet {
            amountErrorRelay.accept(amountError)
        }
    }

    private let addressErrorRelay = PublishRelay<Error?>()
    private var addressError: Error? {
        didSet {
            addressErrorRelay.accept(addressError)
        }
    }

    init(coin: Coin, adapter: ISendEthereumAdapter) {
        sendCoin = coin
        self.adapter = adapter
    }

    private func syncState() {
        if amountError == nil, addressError == nil, let evmAmount = evmAmount, let addressData = addressData {
            let transactionData = adapter.transactionData(amount: evmAmount, address: addressData.evmAddress)
            let sendInfo = SendEvmData.SendInfo(domain: addressData.domain)

            let sendData = SendEvmData(transactionData: transactionData, additionalInfo: .send(info: sendInfo))
            state = .ready(sendData: sendData)
        } else {
            state = .notReady
        }
    }

    private func validEvmAmount(amount: Decimal) throws -> BigUInt {
        guard let evmAmount = BigUInt(amount.roundedString(decimal: sendCoin.decimal)) else {
            throw AmountError.invalidDecimal
        }

        guard amount <= adapter.balance else {
            throw AmountError.insufficientBalance
        }

        return evmAmount
    }

}

extension SendEvmService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var amountErrorObservable: Observable<Error?> {
        amountErrorRelay.asObservable()
    }

}

extension SendEvmService: IAvailableBalanceService {

    var availableBalance: Decimal {
        adapter.balance
    }

}

extension SendEvmService: IAmountInputService {

    var amount: Decimal {
        0
    }

    var coin: Coin? {
        sendCoin
    }

    var balance: Decimal? {
        adapter.balance
    }

    var amountObservable: Observable<Decimal> {
        .empty()
    }

    var coinObservable: Observable<Coin?> {
        .empty()
    }

    func onChange(amount: Decimal) {
        if amount > 0 {
            do {
                evmAmount = try validEvmAmount(amount: amount)
                amountError = nil
            } catch {
                evmAmount = nil
                amountError = error
            }
        } else {
            evmAmount = nil
            amountError = nil
        }

        syncState()
    }

}

extension SendEvmService: IRecipientAddressService {

    var initialAddress: Address? {
        nil
    }

    var error: Error? {
        addressError
    }

    var errorObservable: Observable<Error?> {
        addressErrorRelay.asObservable()
    }

    func set(address: Address?) {
        if let address = address, !address.raw.isEmpty {
            do {
                addressData = AddressData(evmAddress: try EthereumKit.Address(hex: address.raw), domain: address.domain)
                addressError = nil
            } catch {
                addressData = nil
                addressError = error.convertedError
            }
        } else {
            addressData = nil
            addressError = nil
        }

        syncState()
    }

    func set(amount: Decimal) {
        // todo
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

    private struct AddressData {
        let evmAddress: EthereumKit.Address
        let domain: String?
    }

}
