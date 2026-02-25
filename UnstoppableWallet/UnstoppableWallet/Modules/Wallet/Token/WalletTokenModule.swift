import SwiftUI

enum WalletTokenModule {
    @ViewBuilder static func view(wallet: Wallet) -> some View {
        if let adapter = Core.shared.adapterManager.adapter(for: wallet) as? StellarAdapter {
            StellarWalletTokenView(wallet: wallet, stellarKit: adapter.stellarKit, asset: adapter.asset)
        } else if let adapter = Core.shared.adapterManager.adapter(for: wallet) as? BitcoinBaseAdapter {
            BitcoinWalletTokenView(wallet: wallet, adapter: adapter)
        } else if let adapter = Core.shared.adapterManager.adapter(for: wallet) as? ZcashAdapter {
            ZcashWalletTokenView(wallet: wallet, adapter: adapter)
        } else if let adapter = Core.shared.adapterManager.adapter(for: wallet) as? BaseTronAdapter {
            TronWalletTokenView(wallet: wallet, adapter: adapter)
        } else if Core.shared.adapterManager.adapter(for: wallet) is MoneroAdapter ||
            Core.shared.adapterManager.adapter(for: wallet) is ZanoAdapter
        {
            MoneroWalletTokenView(wallet: wallet)
        } else {
            WalletTokenView(wallet: wallet)
        }
    }
}
