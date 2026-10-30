import Combine
import Foundation
import MarketKit
import RxSwift
import SwiftUI
import ZODLSwiftWalletSDK

/// Shields the transparent balance so a send or swap can spend it (Android `ActionShield`), and waits out a
/// shielding or confirming private funds. The step lasts until the shielded funds are spendable, not just until
/// the shielding is broadcast.
class ZcashShieldStepHandler: SpendStepHandler {
    override class func instance(wallet: Wallet, purpose: SpendStepPurpose) -> ISpendStepHandler? {
        guard wallet.token.blockchainType == .zcash, wallet.token.type == .native,
              let adapter = Core.shared.adapterManager.adapter(for: wallet) as? ZcashAdapter
        else {
            return nil
        }

        return ZcashShieldStepHandler(token: wallet.token, adapter: adapter, purpose: purpose)
    }

    private let token: Token
    private let adapter: ZcashAdapter
    private let purpose: SpendStepPurpose

    // sync runs only on this queue so two refreshes never interleave; the lock guards the snapshot because
    // the forms read it from the main thread
    private let syncQueue = DispatchQueue(label: "\(AppConfig.label).zcash-shield-step-handler", qos: .userInitiated)
    private let stateLock = NSLock()
    private var _snapshot = Snapshot(balance: .empty(id: ""), shieldingProgress: nil, heldOutput: 0)

    private let updatedSubject = PassthroughSubject<Void, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: ZcashAdapter, purpose: SpendStepPurpose) {
        self.token = token
        self.adapter = adapter
        self.purpose = purpose

        super.init()

        let scheduler = SerialDispatchQueueScheduler(queue: syncQueue, internalSerialQueueName: "\(AppConfig.label).zcash-shield-step-handler-rx")

        adapter.balanceDataUpdatedObservable
            .observeOn(scheduler)
            .subscribe { [weak self] _ in self?.sync() }
            .disposed(by: disposeBag)

        adapter.lastBlockUpdatedObservable
            .observeOn(scheduler)
            .subscribe { [weak self] _ in self?.sync() }
            .disposed(by: disposeBag)

        adapter.transactionsObservable(token: nil, filter: .all, address: nil)
            .observeOn(scheduler)
            .subscribe { [weak self] _ in self?.sync() }
            .disposed(by: disposeBag)

        syncQueue.sync { sync() }
    }

    /// Runs on syncQueue only: the pool scans its whole set for the latest transactions.
    private func sync() {
        let lastBlockHeight = adapter.lastBlockInfo?.height ?? 0
        let threshold = ZcashSDK.defaultRewindDistance

        let shieldingProgress: Double?
        if adapter.sentShieldingPending {
            shieldingProgress = 0
        } else if let latest = adapter.latestOwnTransaction(lastBlockHeight: lastBlockHeight), latest.shieldDirection == .shield {
            shieldingProgress = ZcashShieldHelper.progress(minedHeight: latest.minedHeight, failed: latest.failed, lastBlockHeight: lastBlockHeight, confirmationsThreshold: threshold)
        } else {
            shieldingProgress = nil
        }

        var heldOutput: Decimal = 0
        if let shielding = adapter.latestShielding(lastBlockHeight: lastBlockHeight), ZcashShieldHelper.isHeld(minedHeight: shielding.minedHeight, lastBlockHeight: lastBlockHeight) {
            heldOutput = shielding.value.decimalValue.decimalValue
        }

        let snapshot = Snapshot(balance: adapter.zCashBalanceData, shieldingProgress: shieldingProgress, heldOutput: heldOutput)
        stateLock.withLock { _snapshot = snapshot }

        updatedSubject.send()
    }

    private var snapshot: Snapshot {
        stateLock.withLock { _snapshot }
    }

    private func title(step: ZcashShieldHelper.Step) -> String {
        switch step {
        case .shield:
            switch purpose {
            case .send: return "send.shield_coin".localized(token.coin.code)
            case .swap: return "swap.shield_coin".localized(token.coin.code)
            }
        case .shielding:
            return "zcash.shielding".localized
        case .confirming:
            return "balance.confirming".localized
        }
    }
}

extension ZcashShieldStepHandler: ISpendStepHandler {
    func step(amount: Decimal) -> SpendStep? {
        let snapshot = snapshot
        let balance = snapshot.balance

        let step = ZcashShieldHelper.step(
            amount: amount,
            available: balance.available,
            full: balance.full,
            transparent: balance.transparent,
            threshold: ZcashAdapter.minimalThreshold,
            shieldingProgress: snapshot.shieldingProgress,
            heldOutput: snapshot.heldOutput
        )

        switch step {
        case nil: return nil
        case .shield: return .required(title: title(step: .shield))
        case let .shielding(progress): return .pending(title: title(step: .shielding(progress: progress)), progress: progress)
        case .confirming: return .pending(title: title(step: .confirming), progress: nil)
        }
    }

    func view(isPresented _: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        // the sent shielding is only a flag until the pool has its record: refresh the snapshot before the form
        // re-reads the step, or it offers the shielding again until the next pool event
        let view = ShieldSendView(amount: snapshot.balance.transparent, address: adapter.uAddress?.stringEncoded) { [weak self] in
            guard let self else {
                onSuccess()
                return
            }

            syncQueue.async {
                self.sync()
                DispatchQueue.main.async(execute: onSuccess)
            }
        }
        return AnyView(ThemeNavigationStack { view })
    }

    var updatedPublisher: AnyPublisher<Void, Never> {
        updatedSubject.eraseToAnyPublisher()
    }
}

extension ZcashShieldStepHandler {
    private struct Snapshot {
        let balance: ZcashBalanceData
        /// Confirmations of the wallet's own shielding in flight over the threshold; nil when none.
        let shieldingProgress: Double?
        /// The output of the newest mined shielding while a proposal does not spend it yet.
        let heldOutput: Decimal
    }
}
