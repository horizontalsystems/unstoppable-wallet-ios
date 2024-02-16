import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit
import RxSwift
import SwiftUI

class MultiSwapApproveViewModel: ObservableObject {
    private let disposeBag = DisposeBag()

    let token: Token

    private let coinService: CoinService
    private let allowanceService: SwapAllowanceService?
    private let pendingAllowanceService: SwapPendingAllowanceService?
    private let approveDataProvider: IApproveDataProvider?

    private let amount: BigUInt
    private let spenderAddress: EvmKit.Address
    var approveData: TransactionData?

    @Published var status: String?
    @Published var unlockEnabled = false
    @Published var useInfinity = false
    @Published var confirmData: TransactionData?
    @Published var dismissed = false

    var presented: Binding<Bool>

    init(token: Token, amount: BigUInt, spenderAddress: EvmKit.Address, presented: Binding<Bool>) {
        let evmKit = App.shared.evmBlockchainManager.evmKitManager(blockchainType: token.blockchainType).evmKitWrapper?.evmKit
        allowanceService = evmKit.map {
            SwapAllowanceService(
                spenderAddress: spenderAddress,
                adapterManager: App.shared.adapterManager,
                evmKit: $0
            )
        }
        allowanceService?.set(token: token)

        self.presented = presented
        pendingAllowanceService = allowanceService.map {
            SwapPendingAllowanceService(
                spenderAddress: spenderAddress,
                adapterManager: App.shared.adapterManager,
                allowanceService: $0
            )
        }

        coinService = CoinService(token: token, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        approveDataProvider = App.shared.adapterManager.adapter(for: token) as? IApproveDataProvider

        self.token = token
        self.spenderAddress = spenderAddress
        self.amount = amount

        // subscribe on current allowance
        if let observable = allowanceService?.stateObservable {
            subscribe(disposeBag, observable) { [weak self] _ in self?.syncState() }
        }
        // subscribe on pending state
        if let observable = pendingAllowanceService?.stateObservable {
            subscribe(disposeBag, observable) { [weak self] _ in self?.syncState() }
        }

        syncState()
    }

    private func syncState() {
        let amount = useInfinity ? BigUInt.infinity : amount

        approveData = nil
        status = nil
        unlockEnabled = false

        let allowanceState = allowanceService?.state ?? .loading
        let pendingState = pendingAllowanceService?.state ?? .notAllowed

        if case .loading = allowanceState {
            status = "action.loading".localized
            return
        }

        if case let .notReady(error) = allowanceState { // something wrong with allowance
            status = error.localizedDescription
            return
        }

        if case let .ready(coinValue) = allowanceState {
            let allowance = coinService.fractionalMonetaryValue(value: coinValue.value)
            if allowance >= amount { // already approved
                status = "swap.approve.amount_error.already_approved".localized
                return
            }
        }

        // Otherwise we check pending status to determine approving or notApproved state
        if case .pending = pendingState { // waiting to approve
            status = "swap.approving_button".localized
            return
        }

        // in all other cases try to get approve data
        if let approveData = approveDataProvider?.approveTransactionData(
            spenderAddress: spenderAddress,
            amount: amount
        ) {
            unlockEnabled = true
            self.approveData = approveData
        } else {
            status = "swap.approve.not_found".localized
        }
    }
}

extension MultiSwapApproveViewModel {
    var amountString: String {
        let coinValue = coinService.coinValue(value: amount)
        return ValueFormatter.instance.formatFull(coinValue: coinValue) ?? coinService.monetaryValue(value: amount).description
    }

    func onApprove() {
        confirmData = approveData
    }

    func set(infinity: Bool) {
        if useInfinity == infinity { return }
        useInfinity = infinity
        syncState()
    }
}

extension MultiSwapApproveViewModel: ISwapApproveDelegate {
    func didApprove() {
        presented.wrappedValue = false
    }
}

extension MultiSwapApproveViewModel {
    enum State {
        case approved
        case approveNotAllowed(errors: [String])
        case approveAllowed(transactionData: TransactionData)
    }
}

extension TransactionData: Identifiable {
    public var id: String {
        [to.raw.hs.hex, value.description, input.description].joined()
    }
}

extension BigUInt {
    static let infinity: Self = .init(2).power(256) - 1
}