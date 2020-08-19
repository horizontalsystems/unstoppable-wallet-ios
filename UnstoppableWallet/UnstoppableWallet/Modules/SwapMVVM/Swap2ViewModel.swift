import Foundation
import RxSwift
import RxCocoa
import UniswapKit

class Swap2ViewModel {
    private let disposeBag = DisposeBag()

    private let service: Swap2Service

    private var isSwapDataLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var isSwapDataHiddenRelay = BehaviorRelay<Bool>(value: true)
    private var swapDataErrorRelay = BehaviorRelay<Error?>(value: nil)
    private var tradeViewItemRelay = BehaviorRelay<Swap2Module.TradeViewItem?>(value: nil)

    private var fromEstimatedRelay = BehaviorRelay<Bool>(value: false)
    private var toEstimatedRelay = BehaviorRelay<Bool>(value: true)
    private var fromBalanceRelay = BehaviorRelay<String?>(value: nil)
    private var balanceErrorRelay = BehaviorRelay<Error?>(value: nil)

    private var isAllowanceHiddenRelay = BehaviorRelay<Bool>(value: true)
    private var isAllowanceLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var allowanceRelay = BehaviorRelay<Swap2Module.AllowanceViewItem?>(value: nil)
    private var allowanceErrorRelay = BehaviorRelay<Error?>(value: nil)

    private var actionTitleRelay = BehaviorRelay<String?>(value: nil)
    private var isActionEnabledRelay = BehaviorRelay<Bool>(value: false)

    init(service: Swap2Service) {
        self.service = service

        subscribeToService()
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.estimated) { [weak self] estimated in self?.handle(estimated: estimated) }
        subscribe(disposeBag, service.balance) { [weak self] coinWithBalance in self?.handle(coinWithBalance: coinWithBalance) }
        subscribe(disposeBag, service.balanceError) { [weak self] error in self?.balanceErrorRelay.accept(error) }
        subscribe(disposeBag, service.allowance) { [weak self] state in self?.handle(allowanceState: state) }
    }

    private func handle<T>(state: DataStatus<T>, loadingRelay: BehaviorRelay<Bool>, errorRelay: BehaviorRelay<Error?>) -> T? {
        if case .loading = state {
            loadingRelay.accept(true)
            return nil
        }
        loadingRelay.accept(false)

        if case .failed(let error) = state {
            errorRelay.accept(error)
            return nil
        }
        errorRelay.accept(nil)

        return state.data
    }

    static private func stringCoinValue(coin: Coin, amount: Decimal?) -> String? {
        guard let amount = amount else {
            return nil
        }
        return ValueFormatter.instance.format(coinValue: CoinValue(coin: coin, value: amount))
    }

    public var fromInputPresenter: ISwapInputPresenter {
        SwapFromInputPresenter(service: service, decimalParser: SendAmountDecimalParser())
    }

    public var toInputPresenter: ISwapInputPresenter {
        SwapToInputPresenter(service: service, decimalParser: SendAmountDecimalParser())
    }

}

extension Swap2ViewModel {

    private func handle(estimated: TradeType) {
        let from = estimated == .exactIn
        let to = estimated == .exactOut

        fromEstimatedRelay.accept(to)
        toEstimatedRelay.accept(from)
    }

    private func handle(coinWithBalance: Swap2Module.CoinWithBalance?) {
        guard let coinWithBalance = coinWithBalance else {
            fromBalanceRelay.accept(nil)
            return
        }

        fromBalanceRelay.accept(Swap2ViewModel.stringCoinValue(coin: coinWithBalance.coin, amount: coinWithBalance.balance))
    }

    private func handle(allowanceState: DataStatus<Swap2Module.AllowanceItem>?) {
        guard let state = allowanceState else {
            isAllowanceHiddenRelay.accept(true)
            return
        }
        isAllowanceHiddenRelay.accept(false)

        guard let allowance = handle(state: state, loadingRelay: isAllowanceLoadingRelay, errorRelay: balanceErrorRelay) else {
            return
        }

        allowanceRelay.accept(Swap2Module.AllowanceViewItem(amount: Swap2ViewModel.stringCoinValue(coin: allowance.coin, amount: allowance.amount), isSufficient: allowance.isSufficient))
    }

}

extension Swap2ViewModel {

    var isSwapDataLoading: Driver<Bool> {
        isSwapDataLoadingRelay.asDriver()
    }

    var swapDataError: Driver<Error?> {
        swapDataErrorRelay.asDriver()
    }

    var fromEstimated: Driver<Bool> {
        fromEstimatedRelay.asDriver()
    }

    var toEstimated: Driver<Bool> {
        toEstimatedRelay.asDriver()
    }

    var fromBalance: Driver<String?> {
        fromBalanceRelay.asDriver()
    }

    var balanceError: Driver<Error?> {
        balanceErrorRelay.asDriver()
    }

    var isAllowanceHidden: Driver<Bool> {
        isAllowanceHiddenRelay.asDriver()
    }

    var isAllowanceLoading: Driver<Bool> {
        isAllowanceLoadingRelay.asDriver()
    }

    var allowance: Driver<Swap2Module.AllowanceViewItem?> {
        allowanceRelay.asDriver()
    }

    var allowanceError: Driver<Error?> {
        allowanceErrorRelay.asDriver()
    }

    var tradeViewItem: Driver<Swap2Module.TradeViewItem?> {
        tradeViewItemRelay.asDriver()
    }

    var actionTitle: Driver<String?> {
        actionTitleRelay.asDriver()
    }

    var isActionEnabled: Driver<Bool> {
        isActionEnabledRelay.asDriver()
    }

    var isSwapDataHidden: Driver<Bool> {
        isSwapDataHiddenRelay.asDriver()
    }

    func onChangeFrom(amount: String?) {
        service.onChange(type: .exactIn, amount: amount)
    }

    func onSelectFrom(coin: Coin) {
    }

    func onChangeTo(amount: String?) {
        service.onChange(type: .exactOut, amount: amount)
    }

    func onSelectTo(coin: Coin) {
    }

    func onTapButton() {
    }

}
