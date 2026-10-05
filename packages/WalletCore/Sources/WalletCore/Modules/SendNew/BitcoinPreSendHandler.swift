import BigInt
import BitcoinCore
import Combine
import Foundation
import Hodler
import MarketKit
import RxSwift
import SwiftUI

class BitcoinPreSendHandler: PreSendHandler {
    override class func instance(wallet: Wallet, address _: ResolvedAddress?) -> IPreSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: wallet) as? BitcoinBaseAdapter else { return nil }
        return BitcoinPreSendHandler(token: wallet.token, adapter: adapter)
    }

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

    let rbfAllowed: Bool
    let lockTimeSupported: Bool

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

    init(token: Token, adapter: BitcoinBaseAdapter) {
        self.token = token
        self.adapter = adapter

        let blockchainType = token.blockchainType
        blockchainManager = Core.shared.btcBlockchainManager

        defaultSortMode = blockchainManager.transactionSortMode(blockchainType: blockchainType)
        sortMode = defaultSortMode

        rbfAllowed = blockchainManager.transactionRbfAllowed(blockchainType: blockchainType)
        defaultRbfEnabled = rbfAllowed ? blockchainManager.transactionRbfEnabled(blockchainType: blockchainType) : false
        rbfEnabled = rbfAllowed ? defaultRbfEnabled : false

        lockTimeSupported = blockchainType == .bitcoin

        super.init()

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

    // The time lock is a sticky user setting: it is applied only where it can be (a direct send to a
    // P2PKH address) and silently skipped everywhere else, without being cleared.
    static func timeLockApplicable(address: String) -> Bool {
        address.hasPrefix("1")
    }

    private func pluginData(address: String) -> [UInt8: IPluginData] {
        guard lockTimeSupported, let lockTimeInterval, Self.timeLockApplicable(address: address) else {
            return [:]
        }

        return [HodlerPlugin.id: HodlerData(lockTimeInterval: lockTimeInterval)]
    }

    private var currentDepositSettings: BitcoinDepositSettings {
        BitcoinDepositSettings(sortMode: sortMode, rbfEnabled: rbfEnabled, customUtxos: customUtxos)
    }

    private func buildSendData(
        amount: Decimal,
        address: String,
        memo: String?,
        pluginData: [UInt8: IPluginData],
        settings: BitcoinDepositSettings
    ) -> SendDataResult {
        do {
            try adapter.validate(address: address, pluginData: pluginData)
        } catch {
            return .invalid(cautions: [CautionNew(title: error.title, text: error.convertedError.localizedDescription, type: .error)])
        }

        let params = SendParameters(
            address: address,
            value: adapter.convertToSatoshi(value: amount),
            sortType: adapter.convertToKitSortMode(sort: settings.sortMode),
            rbfEnabled: settings.rbfEnabled,
            memo: memo,
            unspentOutputs: settings.customUtxos,
            pluginData: pluginData
        )

        return .valid(sendData: .bitcoin(token: token, params: params))
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

    // Chain-constant, so it reads the one table rather than restating it: a memo here becomes an
    // OP_RETURN output (.onChainPublic).
    func memoType(address _: String?) -> MemoType {
        token.blockchainType.memoType
    }

    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationStack {
            BitcoinSendSettingsView(handler: self, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        buildSendData(amount: amount, address: address, memo: memo, pluginData: pluginData(address: address), settings: currentDepositSettings)
    }

    func depositSendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        depositSendData(amount: amount, address: address, memo: memo, settings: nil)
    }

    // The time lock is never part of the snapshot and plugin data is always empty: a deposit address
    // must receive a plain, immediately spendable transfer.
    var depositSettingsSnapshot: PreSendSettingsSnapshot? {
        PreSendSettingsSnapshot(bitcoin: currentDepositSettings)
    }

    func depositSendData(amount: Decimal, address: String, memo: String?, settings: PreSendSettingsSnapshot?) -> SendDataResult {
        buildSendData(amount: amount, address: address, memo: memo, pluginData: [:], settings: settings?.bitcoin ?? currentDepositSettings)
    }
}

// The deposit-relevant subset of the Bitcoin send settings, as immutable values. `@unchecked` only
// because BitcoinCore's UnspentOutputInfo (a plain struct of Int/Data/TimeInterval/String?) does not
// declare Sendable; every stored property is a value type.
struct BitcoinDepositSettings: @unchecked Sendable {
    let sortMode: TransactionDataSortMode
    let rbfEnabled: Bool
    let customUtxos: [UnspentOutputInfo]?
}
