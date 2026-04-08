import HdWalletKit
import MarketKit
import RxSwift
import SwiftUI
import UIKit

enum RestoreSelectModule {
    static func supportedTokens(accountType: AccountType) -> [Token] {
        let tokenQueries = BlockchainType.supported.map(\.nativeTokenQueries).flatMap { $0 }
        let allTokens = (try? Core.shared.marketKit.tokens(queries: tokenQueries)) ?? []
        return allTokens.filter { accountType.supports(token: $0) }
    }

    static func restoreSingleBlockchain(accountName: String, accountType: AccountType, token: Token, backedUp: Bool = true, fileBackedUp: Bool = false) {
        let account = Core.shared.accountFactory.account(
            type: accountType,
            origin: .restored,
            backedUp: backedUp,
            fileBackedUp: fileBackedUp,
            name: accountName
        )
        Core.shared.accountManager.save(account: account)
        Core.shared.restoreStateManager.setShouldRestore(account: account, blockchainType: token.blockchainType)
        Core.shared.walletManager.save(wallets: [Wallet(token: token, account: account)])
    }

    static func viewController(accountName: String, accountType: AccountType, statPage: StatPage, isManualBackedUp: Bool = true, isFileBackedUp: Bool = false, onRestore: @escaping () -> Void) -> UIViewController {
        let (blockchainTokensService, blockchainTokensView) = BlockchainTokensModule.module()
        let (restoreSettingsService, restoreSettingsView) = RestoreSettingsModule.module(statPage: .restoreSelect)

        let service = RestoreSelectService(
            accountName: accountName,
            accountType: accountType,
            statPage: statPage,
            isManualBackedUp: isManualBackedUp,
            isFileBackedUp: isFileBackedUp,
            accountFactory: Core.shared.accountFactory,
            accountManager: Core.shared.accountManager,
            walletManager: Core.shared.walletManager,
            restoreStateManager: Core.shared.restoreStateManager,
            marketKit: Core.shared.marketKit,
            blockchainTokensService: blockchainTokensService,
            restoreSettingsService: restoreSettingsService
        )

        let viewModel = RestoreSelectViewModel(service: service)

        return RestoreSelectViewController(
            viewModel: viewModel,
            blockchainTokensView: blockchainTokensView,
            restoreSettingsView: restoreSettingsView,
            onRestore: onRestore
        )
    }
}

struct RestoreSelectWrapper: UIViewControllerRepresentable {
    let accountName: String
    let accountType: AccountType
    let statPage: StatPage
    var isManualBackedUp: Bool = true
    var isFileBackedUp: Bool = false
    let onRestore: () -> Void

    func makeUIViewController(context _: Context) -> UIViewController {
        RestoreSelectModule.viewController(
            accountName: accountName,
            accountType: accountType,
            statPage: statPage,
            isManualBackedUp: isManualBackedUp,
            isFileBackedUp: isFileBackedUp,
            onRestore: onRestore
        )
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
