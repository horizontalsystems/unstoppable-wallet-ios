import MarketKit
import RxSwift
import SwiftUI

import UIKit

enum WalletModule {
    static func viewController() -> UIViewController {
        let coinPriceService = WalletCoinPriceService(
            currencyManager: App.shared.currencyManager,
            priceChangeModeManager: App.shared.priceChangeModeManager,
            marketKit: App.shared.marketKit
        )

        let walletServiceFactory = WalletServiceFactory(
            adapterManager: App.shared.adapterManager,
            walletManager: App.shared.walletManager
        )

        let service = WalletServiceOld(
            walletServiceFactory: walletServiceFactory,
            coinPriceService: coinPriceService,
            accountManager: App.shared.accountManager,
            cacheManager: App.shared.enabledWalletCacheManager,
            accountRestoreWarningManager: App.shared.accountRestoreWarningManager,
            reachabilityManager: App.shared.reachabilityManager,
            appSettingManager: App.shared.appSettingManager,
            balanceHiddenManager: App.shared.balanceHiddenManager,
            buttonHiddenManager: App.shared.walletButtonHiddenManager,
            balanceConversionManager: App.shared.balanceConversionManager,
            cloudAccountBackupManager: App.shared.cloudBackupManager,
            rateAppManager: App.shared.rateAppManager,
            appManager: App.shared.appManager,
            feeCoinProvider: App.shared.feeCoinProvider,
            userDefaultsStorage: App.shared.userDefaultsStorage
        )

        coinPriceService.delegate = service

        let accountRestoreWarningFactory = AccountRestoreWarningFactory(
            userDefaultsStorage: App.shared.userDefaultsStorage,
            languageManager: LanguageManager.shared
        )

        let viewModel = WalletViewModel(
            service: service,
            eventHandler: App.shared.appEventHandler,
            factory: WalletViewItemFactory(),
            accountRestoreWarningFactory: accountRestoreWarningFactory
        )

        return WalletViewController(viewModel: viewModel)
    }

    static func sendTokenListViewController(allowedBlockchainTypes: [BlockchainType]? = nil, allowedTokenTypes: [TokenType]? = nil, address: String? = nil, amount: Decimal? = nil) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService(
            currencyManager: App.shared.currencyManager,
            priceChangeModeManager: App.shared.priceChangeModeManager,
            marketKit: App.shared.marketKit
        )

        let adapterService = WalletAdapterService(account: account, adapterManager: App.shared.adapterManager)
        let walletService = WalletService(
            account: account,
            adapterService: adapterService,
            walletManager: App.shared.walletManager,
            allowedBlockchainTypes: allowedBlockchainTypes,
            allowedTokenTypes: allowedTokenTypes
        )
        adapterService.delegate = walletService

        let service = WalletTokenListService(
            walletService: walletService,
            coinPriceService: coinPriceService,
            cacheManager: App.shared.enabledWalletCacheManager,
            reachabilityManager: App.shared.reachabilityManager,
            appSettingManager: App.shared.appSettingManager,
            balanceHiddenManager: App.shared.balanceHiddenManager,
            appManager: App.shared.appManager,
            feeCoinProvider: App.shared.feeCoinProvider,
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
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService(
            currencyManager: App.shared.currencyManager,
            priceChangeModeManager: App.shared.priceChangeModeManager,
            marketKit: App.shared.marketKit
        )

        let adapterService = WalletAdapterService(account: account, adapterManager: App.shared.adapterManager)
        let walletService = WalletService(
            account: account,
            adapterService: adapterService,
            walletManager: App.shared.walletManager
        )
        adapterService.delegate = walletService

        let service = WalletTokenListService(
            walletService: walletService,
            coinPriceService: coinPriceService,
            cacheManager: App.shared.enabledWalletCacheManager,
            reachabilityManager: App.shared.reachabilityManager,
            appSettingManager: App.shared.appSettingManager,
            balanceHiddenManager: App.shared.balanceHiddenManager,
            appManager: App.shared.appManager,
            feeCoinProvider: App.shared.feeCoinProvider,
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
        if let account = App.shared.accountManager.activeAccount, !account.watchAccount {
            let coinPriceService = WalletCoinPriceService(
                currencyManager: App.shared.currencyManager,
                priceChangeModeManager: App.shared.priceChangeModeManager,
                marketKit: App.shared.marketKit
            )

            let adapterService = WalletAdapterService(account: account, adapterManager: App.shared.adapterManager)
            let walletService = WalletService(
                account: account,
                adapterService: adapterService,
                walletManager: App.shared.walletManager
            )
            adapterService.delegate = walletService

            let tokenListService = WalletTokenListService(
                walletService: walletService,
                coinPriceService: coinPriceService,
                cacheManager: App.shared.enabledWalletCacheManager,
                reachabilityManager: App.shared.reachabilityManager,
                appSettingManager: App.shared.appSettingManager,
                balanceHiddenManager: App.shared.balanceHiddenManager,
                appManager: App.shared.appManager,
                feeCoinProvider: App.shared.feeCoinProvider,
                account: account
            )
            walletService.delegate = tokenListService
            coinPriceService.delegate = tokenListService

            service = tokenListService
        } else {
            service = NoAccountWalletTokenListService(
                reachabilityManager: App.shared.reachabilityManager,
                appSettingManager: App.shared.appSettingManager
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
