import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import ThemeKit


//TODO: move to another place
func subscribe<T>(_ disposeBag: DisposeBag, _ driver: Driver<T>, _ onNext: ((T) -> Void)? = nil) {
    driver.drive(onNext: onNext).disposed(by: disposeBag)
}

protocol ISwap2ViewModel {
    var isSwapDataLoading: Driver<Bool> { get }
    var swapDataError: Driver<Error?> { get }
    var isSwapDataHidden: Driver<Bool> { get }
    var estimated: Driver<TradeType> { get }
    var fromAmount: Driver<String?> { get }
    var fromTokenCode: Driver<String> { get }
    var fromBalance: Driver<String?> { get }
    var balanceError: Driver<Error?> { get }
    var isAllowanceHidden: Driver<Bool> { get }
    var isAllowanceLoading: Driver<Bool> { get }
    var allowance: Driver<String?> { get }
    var allowanceError: Driver<Error?> { get }
    var toAmount: Driver<String?> { get }
    var toTokenCode: Driver<String> { get }
    var tradeViewItem: Driver<Swap2Module.TradeViewItem?> { get }
    var actionTitle: Driver<String?> { get }
    var isActionEnabled: Driver<Bool> { get }

    func onChangeFrom(amount: String?)
    func onSelectFrom(coin: Coin)

    func onChangeTo(amount: String?)
    func onSelectTo(coin: Coin)

    func onTapButton()
}


struct Swap2Module {

    enum PriceImpactLevel: Int {
    case normal
    case warning
    case forbidden
    }

    struct TradeItem {
        let type: TradeType
        let amountIn: Decimal?
        let amountOut: Decimal?
        let executionPrice: Decimal?
        let priceImpact: Decimal?
        let minMaxAmount: Decimal?
    }

    struct TradeViewItem {
        let executionPrice: String?
        let priceImpact: String?
        let priceImpactLevel: PriceImpactLevel
        let minMaxTitle: String?
        let minMaxAmount: String?
    }

    struct AllowanceItem {
        let coin: Coin
        let amount: Decimal
        let isSufficient: Bool
    }

    struct AllowanceViewItem {
        let amount: String?
        let isSufficient: Bool
    }

    enum ActionType {
        case proceed
        case approve
        case approving
    }

    static func instance(wallet: Wallet) -> UIViewController? {
        guard let ethereumKit = try? App.shared.ethereumKitManager.ethereumKit(account: wallet.account) else {
            return nil
        }
        let swapKit = UniswapKit.Kit.instance(ethereumKit: ethereumKit)
        let allowanceRepository = AllowanceRepository(walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager)
//        let decimalParser = SendAmountDecimalParser()

        let service = Swap2Service(uniswapRepository: UniswapRepository(swapKit: swapKit), allowanceRepository: allowanceRepository, coin: wallet.coin)
        let viewModel = Swap2ViewModel(service: service)

        return ThemeNavigationController(rootViewController: Swap2ViewController(viewModel: viewModel))
    }

}
