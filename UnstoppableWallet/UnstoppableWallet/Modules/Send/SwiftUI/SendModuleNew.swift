import MarketKit
import SwiftUI

enum SendModuleNew {
    static func view(adapter _: ISendTonAdapter) -> some View {
        let token = try? App.shared.marketKit.token(query: TokenQuery(blockchainType: .ton, tokenType: .native))

        let viewModel = SendViewModelNew(token: token!)
        return SendView(viewModel: viewModel)
    }

    static func amountView(token: Token) -> some View {
        let viewModel = SendAmountViewModel(token: token, currencyManager: App.shared.currencyManager)
        return SendAmountView(viewModel: viewModel)
    }
}
