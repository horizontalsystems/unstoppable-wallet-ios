import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import ThemeKit


//TODO: move to another place
func subscribe<T>(_ disposeBag: DisposeBag, _ driver: Driver<T>, _ onNext: ((T) -> Void)? = nil) {
    driver.drive(onNext: onNext).disposed(by: disposeBag)
}

func subscribe<T>(_ disposeBag: DisposeBag, _ observable: Observable<T>, _ onNext: ((T) -> Void)? = nil) {
    observable.subscribe(onNext: onNext).disposed(by: disposeBag)
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

    struct CoinWithBalance {
        let coin: Coin
        let balance: Decimal?
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
        let decimalParser = SendAmountDecimalParser()

        let service = Swap2Service(uniswapRepository: UniswapRepository(swapKit: swapKit), allowanceRepository: allowanceRepository, adapterManager: App.shared.adapterManager, decimalParser: decimalParser, coin: wallet.coin)
        let viewModel = Swap2ViewModel(service: service)

        return ThemeNavigationController(rootViewController: Swap2ViewController(viewModel: viewModel))
    }

}
