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
    let defaultSortMode: TransactionDataSortMode
    let defaultRbfEnabled: Bool

    var customUtxos: [UnspentOutputInfo]? {
        didSet {
            balanceSubject.send(availableBalanceDecimal)
            settingsModifiedSubject.send(settingsModified)
        }
    }

    var sortMode: TransactionDataSortMode {
        didSet {
            blockchainManager.save(transactionSortMode: sortMode, blockchainType: token.blockchainType)
            settingsModifiedSubject.send(settingsModified)
        }
    }

    var rbfEnabled: Bool {
        didSet {
            blockchainManager.save(rbfEnabled: rbfEnabled, blockchainType: token.blockchainType)
            settingsModifiedSubject.send(settingsModified)
        }
    }

    var lockTimeInterval: HodlerPlugin.LockTimeInterval? {
        didSet {
            settingsModifiedSubject.send(settingsModified)
        }
    }

    var allUtxos = [UnspentOutputInfo]()
    var availableBalance: Int {
        let utxos = customUtxos ?? allUtxos
        return utxos.map(\.value).reduce(0, +)
    }

    var availableBalanceDecimal: Decimal {
        let coinRate = pow(10, token.decimals)
        return Decimal(availableBalance) / coinRate
    }

    private let adapter: BitcoinBaseAdapter
    private let blockchainManager: BtcBlockchainManager
    private let disposeBag = DisposeBag()

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()
    private let settingsModifiedSubject = PassthroughSubject<Bool, Never>()

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
        blockchainManager = Core.shared.btcBlockchainManager

        defaultSortMode = blockchainManager.transactionSortMode(blockchainType: blockchainType)
        sortMode = defaultSortMode

        defaultRbfEnabled = blockchainManager.transactionRbfEnabled(blockchainType: blockchainType)
        rbfEnabled = defaultRbfEnabled

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
        availableBalanceDecimal
    }

    var balancePublisher: AnyPublisher<Decimal, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    var settingsModified: Bool {
        sortMode != defaultSortMode || rbfEnabled != defaultRbfEnabled || customUtxos != nil || lockTimeInterval != nil
    }

    var settingsModifiedPublisher: AnyPublisher<Bool, Never> {
        settingsModifiedSubject.eraseToAnyPublisher()
    }

    func hasMemo(address _: String?) -> Bool {
        true
    }

    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationStack {
            BitcoinSendSettingsView(handler: self, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        do {
            try adapter.validate(address: address, pluginData: pluginData)
        } catch {
            return .invalid(cautions: [CautionNew(title: error.title, text: error.convertedError.localizedDescription, type: .error)])
        }

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
