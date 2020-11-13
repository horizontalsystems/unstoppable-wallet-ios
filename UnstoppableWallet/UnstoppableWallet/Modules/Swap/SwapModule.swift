import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import EthereumKit
import ThemeKit
import CurrencyKit
import BigInt

//TODO: move to another place
func subscribe<T>(_ disposeBag: DisposeBag, _ driver: Driver<T>, _ onNext: ((T) -> Void)? = nil) {
    driver.drive(onNext: onNext).disposed(by: disposeBag)
}

func subscribe<T>(_ disposeBag: DisposeBag, _ signal: Signal<T>, _ onNext: ((T) -> Void)? = nil) {
    signal.emit(onNext: onNext).disposed(by: disposeBag)
}

func subscribe<T>(_ disposeBag: DisposeBag, _ observable: Observable<T>, _ onNext: ((T) -> Void)? = nil) {
    observable.subscribe(onNext: onNext).disposed(by: disposeBag)
}

struct SwapModule {

    enum SwapState {
        case idle
        case approveRequired
        case waitingForApprove
        case proceedAllowed
        case swapping
        case swapSuccess
    }

    enum PriceImpactLevel: Int {
    case none
    case normal
    case warning
    case forbidden
    }

    struct TradeItem {
        let coinIn: Coin
        let coinOut: Coin
        let type: TradeType
        let executionPrice: Decimal?
        let priceImpact: Decimal?
        let priceImpactLevel: PriceImpactLevel
        let providerFee: Decimal?
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
        let amount: CoinValue
        let isSufficient: Bool
    }

    struct AllowanceViewItem {
        let amount: String?
        let isSufficient: Bool
    }

    struct ApproveData {
        let coin: Coin
        let spenderAddress: Address
        let amount: BigUInt
        let allowance: BigUInt
    }

    struct CoinBalanceItem {
        let coin: Coin
        let balance: Decimal?
        let blockchainType: String?
    }

    struct ConfirmationAdditionalViewItem {
        let title: String
        let value: String?
    }

    struct ConfirmationAmountViewItem {
        let payTitle: String
        let payValue: String?
        let getTitle: String
        let getValue: String?
    }

    struct SwapFeeInfo {
        let gasPrice: Int
        let gasLimit: Int
        let coinAmount: CoinValue
        let currencyAmount: CurrencyValue?
    }

    static func instance(wallet: Wallet) -> UIViewController? {
        let feeCoin = App.shared.feeCoinProvider.feeCoin(coin: wallet.coin) ?? wallet.coin

        guard let ethereumKit = try? App.shared.ethereumKitManager.ethereumKit(account: wallet.account),
              let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: feeCoin.type) else {
            return nil
        }
        let swapKit = UniswapKit.Kit.instance(ethereumKit: ethereumKit)
        let allowanceRepository = AllowanceProvider(walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager)
        let swapCoinProvider = SwapCoinProvider(coinManager: App.shared.coinManager, walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager)

        let swapFeeRepository = SwapFeeRepository(uniswapKit: swapKit, adapterManager: App.shared.adapterManager, provider: feeRateProvider, rateManager: App.shared.rateManager, baseCurrency: App.shared.currencyKit.baseCurrency, feeCoin: feeCoin)
        let service = SwapService(uniswapRepository: UniswapRepository(swapKit: swapKit), allowanceRepository: allowanceRepository, swapFeeRepository: swapFeeRepository, swapCoinProvider: swapCoinProvider, adapterManager: App.shared.adapterManager, coin: wallet.coin)
        let viewModel = SwapViewModel(service: service, factory: SwapViewItemHelper(), decimalParser: AmountDecimalParser())

        return ThemeNavigationController(rootViewController: SwapViewController(viewModel: viewModel))
    }

    static func viewController(coinIn: Coin) -> UIViewController? {
        guard let ethereumKit = App.shared.ethereumKitManager.ethereumKit else {
            return nil
        }

        let swapKit = UniswapKit.Kit.instance(ethereumKit: ethereumKit)
        let uniswapRepository = UniswapRepository(swapKit: swapKit)

        let coinService = CoinService(
                coin: App.shared.appConfigProvider.ethereumCoin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let tradeService = SwapTradeService(
                uniswapRepository: uniswapRepository,
                coin: coinIn
        )
        let allowanceService = SwapAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManager,
                ethereumKit: ethereumKit
        )
        let pendingAllowanceService = SwapPendingAllowanceService(
                spenderAddress: uniswapRepository.routerAddress,
                adapterManager: App.shared.adapterManager,
                allowanceService: allowanceService
        )
        let transactionService = EthereumTransactionService(
                ethereumKit: ethereumKit,
                feeRateProvider: App.shared.feeRateProviderFactory.provider(coinType: .ethereum) as! EthereumFeeRateProvider
        )
        let service = SwapServiceNew(
                ethereumKit: ethereumKit,
                tradeService: tradeService,
                allowanceService: allowanceService,
                pendingAllowanceService: pendingAllowanceService,
                transactionService: transactionService,
                adapterManager: App.shared.adapterManager
        )

        let allowanceViewModel = SwapAllowanceViewModelNew(service: service, allowanceService: allowanceService)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinService)
        let viewModel = SwapViewModelNew(
                service: service,
                tradeService: tradeService,
                transactionService: transactionService,
                pendingAllowanceService: pendingAllowanceService,
                coinService: coinService,
                viewItemHelper: SwapViewItemHelper()
        )

        let viewController = SwapViewControllerNew(
                viewModel: viewModel,
                allowanceViewModel: allowanceViewModel,
                feeViewModel: feeViewModel
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

enum SwapValidationError: Hashable, Error, LocalizedError {
    case unavailableBalance(type: TradeType)
    case insufficientBalance
    case insufficientAllowance

    var errorDescription: String? {
        switch self {
        case .insufficientAllowance:
            return "swap.allowance_error.insufficient_allowance".localized
        default: return ""
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .unavailableBalance(let type):
            hasher.combine(type)
        case .insufficientBalance:
            hasher.combine("balance")
        case .insufficientAllowance:
            hasher.combine("allowance")
        }
    }

    static func ==(lhs: SwapValidationError, rhs: SwapValidationError) -> Bool {
        switch (lhs, rhs) {
        case (unavailableBalance(let lhsType), unavailableBalance(let rhsType)): return lhsType == rhsType
        case (insufficientBalance, insufficientBalance), (insufficientAllowance, insufficientAllowance): return true
        default: return false
        }
    }
}

extension UniswapKit.Kit.TradeError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .tradeNotFound: return "swap.trade_error.not_found".localized
        default: return nil
        }
    }

}
