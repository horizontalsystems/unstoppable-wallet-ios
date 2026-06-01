import MarketKit

enum TransactionServiceFactory {
    static func transactionService(sendData: SendData, baseToken: Token, initialTransactionSettings: InitialTransactionSettings?) -> ITransactionService? {
        let activeAccount = Core.shared.accountManager.activeAccount

        if let activeAccount, case .passkeyOwned = activeAccount.type,
           EvmBlockchainManager.blockchainTypes.contains(baseToken.blockchainType),
           let aaService = AaTransactionService(blockchainType: baseToken.blockchainType, account: activeAccount, initialTransactionSettings: initialTransactionSettings)
        {
            return aaService
        }

        if EvmBlockchainManager.blockchainTypes.contains(baseToken.blockchainType),
           let evmKit = try? Core.shared.evmBlockchainManager.evmKitManager(blockchainType: baseToken.blockchainType).evmKitWrapper?.evmKit,
           let transactionService = EvmTransactionService(blockchainType: baseToken.blockchainType, evmKit: evmKit, initialTransactionSettings: initialTransactionSettings)
        {
            return transactionService
        }

        if BtcBlockchainManager.blockchainTypes.contains(baseToken.blockchainType), let adapter = Core.shared.adapterManager.adapter(for: baseToken) as? BitcoinBaseAdapter {
            return UtxoTransactionService(blockchainType: baseToken.blockchainType, adapter: adapter)
        }

        if baseToken.blockchainType == .monero, let adapter = Core.shared.adapterManager.adapter(for: baseToken) as? MoneroAdapter {
            return MoneroTransactionService(adapter: adapter)
        }

        if baseToken.blockchainType == .zcash {
            switch sendData {
            case let .zcash(amount, recipient, memo),
                 let .zcashResend(amount, recipient, memo, _):
                return ZcashTransactionService(
                    token: baseToken,
                    proposalRequest: .transfer(amount: amount, recipient: recipient, memo: memo),
                    initialTransactionSettings: initialTransactionSettings
                )
            default: ()
            }
        }

        return nil
    }
}
