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
    private let addressParserChain: AddressParserChain

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var evmAmount: BigUInt?
    private var addressData: AddressData?

    private let addressStateRelay = PublishRelay<AddressParserChain.State>()
    private(set) var addressState: AddressParserChain.State = .empty {
        didSet {
            addressStateRelay.accept(addressState)
        }
    }

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

    init(platformCoin: PlatformCoin, adapter: ISendEthereumAdapter, addressParserChain: AddressParserChain) {
        sendPlatformCoin = platformCoin
        self.adapter = adapter
        self.addressParserChain = addressParserChain

        subscribe(disposeBag, addressParserChain.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: AddressParserChain.State) {
        if case let .success(address) = state {
            do {
                addressData = AddressData(evmAddress: try EthereumKit.Address(hex: address.raw), domain: address.domain)
            } catch {
                addressData = nil
            }
        }

        addressState = state
        syncState()
    }

    private func syncState() {
        if amountCaution.error == nil, case .success = addressState, let evmAmount = evmAmount, let addressData = addressData {
            let transactionData = adapter.transactionData(amount: evmAmount, address: addressData.evmAddress)
            let sendInfo = SendEvmData.SendInfo(domain: addressData.domain)

            let sendData = SendEvmData(transactionData: transactionData, additionalInfo: .send(info: sendInfo))
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

extension SendEvmService: IRecipientAddressService {

    var addressStateObservable: Observable<AddressParserChain.State> {
        addressStateRelay.asObservable()
    }

    var recipientError: Error? {
        addressError
    }

    var recipientErrorObservable: Observable<Error?> {
        addressErrorRelay.asObservable()
    }

    func set(address: String?) {
        if let address = address, !address.isEmpty {
            addressParserChain.handle(address: address)
        }
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

    enum AmountWarning {
        case coinNeededForFee
    }

    private struct AddressData {
        let evmAddress: EthereumKit.Address
        let domain: String?
    }

}
