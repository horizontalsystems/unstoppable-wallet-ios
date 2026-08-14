import Combine
import Foundation
import MarketKit
import MoneroKit
import RxSwift
import SwiftUI

class MoneroPreSendHandler: PreSendHandler {
    override class func instance(wallet: Wallet, address _: ResolvedAddress) -> IPreSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: wallet) as? MoneroAdapter else { return nil }
        return MoneroPreSendHandler(token: wallet.token, adapter: adapter)
    }

    let token: Token
    private let adapter: MoneroAdapter

    private(set) var allOutputs = [MoneroKit.UnspentOutput]()
    private(set) var transactionTimestamps = [String: Int]()

    // nil = automatic input selection by the wallet
    var customOutputs: [MoneroKit.UnspentOutput]? {
        didSet {
            balanceSubject.send(availableBalance)
            settingsModifiedSubject.send(settingsModified)
        }
    }

    private let stateSubject = PassthroughSubject<AdapterState, Never>()
    private let balanceSubject = PassthroughSubject<Decimal, Never>()
    private let settingsModifiedSubject = PassthroughSubject<Bool, Never>()

    private let disposeBag = DisposeBag()

    init(token: Token, adapter: MoneroAdapter) {
        self.token = token
        self.adapter = adapter

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
                self?.syncOutputs()
                if let self {
                    balanceSubject.send(availableBalance)
                }
            }
            .disposed(by: disposeBag)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.syncOutputs()
            if let self {
                balanceSubject.send(availableBalance)
            }
        }
    }

    // Runs on a background queue: output enumeration takes the wallet mutex.
    private func syncOutputs() {
        allOutputs = (try? adapter.unspentOutputs())?.filter(\.spendable) ?? []
        transactionTimestamps = adapter.transactionTimestamps()

        // Prune selections referencing outputs that disappeared during sync
        if let customOutputs {
            let validKeyImages = Set(allOutputs.map(\.keyImage))
            let pruned = customOutputs.filter { validKeyImages.contains($0.keyImage) }
            if pruned.count != customOutputs.count {
                self.customOutputs = pruned
            }
        }
    }

    var availableBalance: Decimal {
        if let customOutputs {
            return Decimal(customOutputs.reduce(0) { $0 + $1.amount }) / adapter.coinRate
        }

        return adapter.balanceData.available
    }

    func subaddress(index: Int) -> String? {
        adapter.subaddress(index: index)
    }
}

extension MoneroPreSendHandler: IPreSendHandler {
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
        availableBalance
    }

    var balancePublisher: AnyPublisher<Decimal, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    var settingsModified: Bool {
        customOutputs != nil
    }

    var settingsModifiedPublisher: AnyPublisher<Bool, Never> {
        settingsModifiedSubject.eraseToAnyPublisher()
    }

    // Chain-constant, so it reads the one table rather than restating it: a Monero memo is a local
    // wallet note (.local).
    func memoType(address _: String?) -> MemoType {
        token.blockchainType.memoType
    }

    func settingsView(onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationStack {
            MoneroSendSettingsView(handler: self, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    func sendData(amount: Decimal, address: String, memo: String?) -> SendDataResult {
        if !MoneroKit.Kit.isValid(address: address, networkType: MoneroAdapter.networkType) {
            return .invalid(cautions: [CautionNew(text: "send.address.invalid_address".localized, type: .error)])
        }

        // Spending the whole available balance is a sweep; with a custom selection the
        // available balance is the selection sum, so the sweep covers exactly those outputs.
        let moneroAmount: MoneroSendAmount
        if amount == availableBalance {
            moneroAmount = .all(amount)
        } else {
            moneroAmount = .value(amount)
        }

        return .valid(sendData: .monero(token: token, amount: moneroAmount, address: address, memo: memo, selectedKeyImages: customOutputs.map { $0.map(\.keyImage) }))
    }
}
