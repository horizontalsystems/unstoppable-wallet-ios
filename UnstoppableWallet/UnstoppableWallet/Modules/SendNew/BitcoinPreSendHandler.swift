import BigInt
import BitcoinCore
import Combine
import Foundation
import Hodler
import MarketKit
import RxSwift
import SwiftUI

class BitcoinPreSendHandler {
    let token: Token

    var sortMode: TransactionDataSortMode
    var rbfEnabled: Bool
    var lockTimeInterval: HodlerPlugin.LockTimeInterval?

    var customUtxos: [UnspentOutputInfo]? {
        didSet {
            syncBalance()
        }
    }

    var allUtxos = [UnspentOutputInfo]()
    var availableBalance: Int {
        let utxos = customUtxos ?? allUtxos
        return utxos.map(\.value).reduce(0, +)
    }

    private let adapter: BitcoinBaseAdapter
    private let disposeBag = DisposeBag()
    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()

    private var pluginData: [UInt8: IPluginData] {
        guard let lockTimeInterval else {
            return [:]
        }

        return [HodlerPlugin.id: HodlerData(lockTimeInterval: lockTimeInterval)]
    }

    init(token: Token, adapter: BitcoinBaseAdapter) {
        self.token = token
        self.adapter = adapter

        let blockchainType = token.blockchainType
        let blockchainManager = App.shared.btcBlockchainManager

        sortMode = blockchainManager.transactionSortMode(blockchainType: blockchainType)
        rbfEnabled = blockchainManager.transactionRbfEnabled(blockchainType: blockchainType)

        adapter.balanceStateUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] state in
                self?.stateSubject.send(state)
            }
            .disposed(by: disposeBag)

        adapter.balanceDataUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe { [weak self] _ in
                self?.syncBalance()
            }
            .disposed(by: disposeBag)

        syncBalance()
    }

    private func syncBalance() {
        allUtxos = adapter.unspentOutputs(filters: .init())

        let coinRate = pow(10, token.decimals)
        let availableBalanceDecimal = Decimal(availableBalance) / coinRate
        balanceSubject.send(availableBalanceDecimal)
    }
}

extension BitcoinPreSendHandler: IPreSendHandler {
    var hasSettings: Bool {
        true
    }

    var state: AdapterState {
        adapter.balanceState
    }

    var statePublisher: AnyPublisher<AdapterState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var balance: Decimal {
        adapter.balanceData.available
    }

    var balancePublisher: AnyPublisher<Decimal, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    func hasMemo(address _: String?) -> Bool {
        true
    }

    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationView {
            BitcoinSendSettingsView(handler: self, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        let params = SendParameters(
            address: address,
            value: adapter.convertToSatoshi(value: amount),
            sortType: adapter.convertToKitSortMode(sort: sortMode),
            rbfEnabled: rbfEnabled,
            memo: memo,
            unspentOutputs: customUtxos,
            pluginData: pluginData
        )

        return .valid(sendData: .bitcoin(token: token, params: params))
    }
}
