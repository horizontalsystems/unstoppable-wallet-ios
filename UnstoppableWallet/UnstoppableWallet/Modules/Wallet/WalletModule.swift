import MarketKit
import RxSwift
import SwiftUI

import UIKit

enum WalletModule {
    static func viewController() -> UIViewController {
        let coinPriceService = WalletCoinPriceService()
        let walletServiceFactory = WalletServiceFactory()

        let service = WalletServiceOld(
            walletServiceFactory: walletServiceFactory,
            coinPriceService: coinPriceService,
            accountManager: Core.shared.accountManager,
            cacheManager: Core.shared.enabledWalletCacheManager,
            accountRestoreWarningManager: Core.shared.accountRestoreWarningManager,
            reachabilityManager: Core.shared.reachabilityManager,
            appSettingManager: Core.shared.appSettingManager,
            balanceHiddenManager: Core.shared.balanceHiddenManager,
            buttonHiddenManager: Core.shared.walletButtonHiddenManager,
            balanceConversionManager: Core.shared.balanceConversionManager,
            cloudAccountBackupManager: Core.shared.cloudBackupManager,
            rateAppManager: Core.shared.rateAppManager,
            appManager: Core.shared.appManager,
            feeCoinProvider: Core.shared.feeCoinProvider,
            userDefaultsStorage: Core.shared.userDefaultsStorage
        )

        coinPriceService.delegate = service

        let accountRestoreWarningFactory = AccountRestoreWarningFactory()

        let viewModel = WalletViewModel(
            service: service,
            eventHandler: Core.shared.appEventHandler,
            factory: WalletViewItemFactory(),
            accountRestoreWarningFactory: accountRestoreWarningFactory
        )

        return WalletViewController(viewModel: viewModel)
    }

    static func sendTokenListViewController(allowedBlockchainTypes: [BlockchainType]? = nil, allowedTokenTypes: [TokenType]? = nil, address: String? = nil, amount: Decimal? = nil) -> UIViewController? {
        guard let account = Core.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService()

        let adapterService = WalletAdapterService(account: account, adapterManager: Core.shared.adapterManager)
        let walletService = WalletService(
            account: account,
            adapterService: adapterService,
            walletManager: Core.shared.walletManager,
            allowedBlockchainTypes: allowedBlockchainTypes,
            allowedTokenTypes: allowedTokenTypes
        )
        adapterService.delegate = walletService

        let service = WalletTokenListService(
            walletService: walletService,
            coinPriceService: coinPriceService,
            cacheManager: Core.shared.enabledWalletCacheManager,
            reachabilityManager: Core.shared.reachabilityManager,
            appSettingManager: Core.shared.appSettingManager,
            balanceHiddenManager: Core.shared.balanceHiddenManager,
            appManager: Core.shared.appManager,
            feeCoinProvider: Core.shared.feeCoinProvider,
            account: account
        )
        walletService.delegate = service
        coinPriceService.delegate = service

        let viewModel = WalletTokenListViewModel(
            service: service,
            factory: WalletTokenListViewItemFactory(),
            title: "send.send".localized,
            emptyText: "send.no_assets".localized
        )

        let dataSourceChain = DataSourceChain()
        let dataSource = WalletTokenListDataSource(viewModel: viewModel)
        dataSource.delegate = dataSourceChain
        dataSourceChain.append(source: dataSource)

        let viewController = WalletTokenListViewController(viewModel: viewModel, dataSource: dataSourceChain)
        dataSource.viewController = viewController
        dataSource.onSelectWallet = { [weak viewController] wallet in
            let module = SendAddressView(
                wallet: wallet,
                address: address,
                amount: amount,
                onDismiss: { viewController?.dismiss(animated: true) }
            ).toViewController()

            viewController?.navigationController?.pushViewController(module, animated: true)
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func swapTokenListViewController() -> UIViewController? {
        guard let account = Core.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService()

        let adapterService = WalletAdapterService(account: account, adapterManager: Core.shared.adapterManager)
        let walletService = WalletService(
            account: account,
            adapterService: adapterService,
            walletManager: Core.shared.walletManager
        )
        adapterService.delegate = walletService

        let service = WalletTokenListService(
            walletService: walletService,
            coinPriceService: coinPriceService,
            cacheManager: Core.shared.enabledWalletCacheManager,
            reachabilityManager: Core.shared.reachabilityManager,
            appSettingManager: Core.shared.appSettingManager,
            balanceHiddenManager: Core.shared.balanceHiddenManager,
            appManager: Core.shared.appManager,
            feeCoinProvider: Core.shared.feeCoinProvider,
            account: account
        )
        service.walletFilter = { wallet in wallet.token.swappable }

        walletService.delegate = service
        coinPriceService.delegate = service

        let viewModel = WalletTokenListViewModel(
            service: service,
            factory: WalletTokenListViewItemFactory(),
            title: "swap.title".localized,
            emptyText: "swap.no_assets".localized
        )

        let dataSourceChain = DataSourceChain()
        let dataSource = WalletTokenListDataSource(viewModel: viewModel)
        dataSource.delegate = dataSourceChain
        dataSourceChain.append(source: dataSource)

        let viewController = WalletTokenListViewController(viewModel: viewModel, dataSource: dataSourceChain)
        dataSource.viewController = viewController
        dataSource.onSelectWallet = { [weak viewController] wallet in
            if let module = SwapModule.viewController(tokenFrom: wallet.token) {
                viewController?.navigationController?.pushViewController(module, animated: true)
            }
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func donateTokenListViewController() -> UIViewController {
        let service: IWalletTokenListService
        if let account = Core.shared.accountManager.activeAccount, !account.watchAccount {
            let coinPriceService = WalletCoinPriceService()

            let adapterService = WalletAdapterService(account: account, adapterManager: Core.shared.adapterManager)
            let walletService = WalletService(
                account: account,
                adapterService: adapterService,
                walletManager: Core.shared.walletManager
            )
            adapterService.delegate = walletService

            let tokenListService = WalletTokenListService(
                walletService: walletService,
                coinPriceService: coinPriceService,
                cacheManager: Core.shared.enabledWalletCacheManager,
                reachabilityManager: Core.shared.reachabilityManager,
                appSettingManager: Core.shared.appSettingManager,
                balanceHiddenManager: Core.shared.balanceHiddenManager,
                appManager: Core.shared.appManager,
                feeCoinProvider: Core.shared.feeCoinProvider,
                account: account
            )
            walletService.delegate = tokenListService
            coinPriceService.delegate = tokenListService

            service = tokenListService
        } else {
            service = NoAccountWalletTokenListService(
                reachabilityManager: Core.shared.reachabilityManager,
                appSettingManager: Core.shared.appSettingManager
            )
        }

        let viewModel = WalletTokenListViewModel(
            service: service,
            factory: WalletTokenListViewItemFactory(),
            title: "donate.list.title".localized,
            emptyText: "donate.no_assets".localized
        )

        let dataSourceChain = DataSourceChain()
        let descriptionDataSource = DonateDescriptionDataSource()
        descriptionDataSource.delegate = dataSourceChain
        dataSourceChain.append(source: descriptionDataSource)

        let dataSource = WalletTokenListDataSource(viewModel: viewModel)
        dataSource.delegate = dataSourceChain
        dataSourceChain.append(source: dataSource)

        let viewController = WalletTokenListViewController(viewModel: viewModel, dataSource: dataSourceChain)
        viewController.hideSearchBar = true

        descriptionDataSource.viewController = viewController
        dataSource.viewController = viewController
        dataSource.onSelectWallet = { [weak viewController] wallet in
            guard let address = AppConfig.donationAddresses.first(where: { $0.key == wallet.token.blockchainType })?.value else {
                return
            }

            let module = PreSendView(
                wallet: wallet,
                handler: SendHandlerFactory.preSendHandler(wallet: wallet),
                resolvedAddress: .init(address: address, issueTypes: []),
                addressVisible: false,
                onDismiss: { viewController?.dismiss(animated: true) }
            )
            .toViewController()

            viewController?.navigationController?.pushViewController(module, animated: true)
            stat(page: .donate, event: .openSend(token: wallet.token))
        }

        return ThemeNavigationController(rootViewController: viewController)
    }
}

extension WalletModule {
    enum Button: CaseIterable {
        case send
        case receive
        case address
        case swap
        case chart
    }

    struct ButtonItem {
        let button: Button
        let state: ButtonState
    }

    enum SortType: String, CaseIterable {
        case balance
        case name
        case percentGrowth

        var title: String {
            switch self {
            case .balance: return "balance.sort.valueHighToLow".localized
            case .name: return "balance.sort.az".localized
            case .percentGrowth: return "balance.sort.price_change".localized
            }
        }
    }

    class HeaderViewItem {
        let amount: String?
        let amountExpired: Bool
        let convertedValue: String?
        let convertedValueExpired: Bool
        let buttons: [WalletModule.Button: ButtonState]

        init(amount: String?, amountExpired: Bool, convertedValue: String?, convertedValueExpired: Bool, buttons: [WalletModule.Button: ButtonState]) {
            self.amount = amount
            self.amountExpired = amountExpired
            self.convertedValue = convertedValue
            self.convertedValueExpired = convertedValueExpired
            self.buttons = buttons
        }
    }
}

struct DonateTokenListView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context _: Context) -> UIViewController {
        WalletModule.donateTokenListViewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

enum WalletButton {
    case send
    case receive
    case address
    case swap
    case chart
    case scan

    var title: String {
        switch self {
        case .send: return "balance.send".localized
        case .receive: return "balance.receive".localized
        case .address: return "balance.address".localized
        case .swap: return "balance.swap".localized
        case .chart: return "balance.chart".localized
        case .scan: return "balance.scan".localized
        }
    }

    var icon: String {
        switch self {
        case .send: return "arrow_medium_2_up_right_24"
        case .receive: return "arrow_medium_2_down_left_24"
        case .address: return "arrow_medium_2_down_left_24"
        case .swap: return "arrow_swap_2_24"
        case .chart: return "chart_2_24"
        case .scan: return "chart_2_24"
        }
    }

    var accent: Bool {
        switch self {
        case .receive: return true
        default: return false
        }
    }
}
