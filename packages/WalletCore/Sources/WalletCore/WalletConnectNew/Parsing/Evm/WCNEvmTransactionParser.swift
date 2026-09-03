import EvmKit
import MarketKit
import OneInchKit
import UniswapKit
import WalletConnectSign

class WCNEvmTransactionParser: IWCNParser {
    private let evmBlockchainManager: EvmBlockchainManager
    private let coinManager: CoinManager
    private let accountManager: AccountManager

    init(evmBlockchainManager: EvmBlockchainManager, coinManager: CoinManager, accountManager: AccountManager) {
        self.evmBlockchainManager = evmBlockchainManager
        self.coinManager = coinManager
        self.accountManager = accountManager
    }

    func parse(request: Request) throws -> WCNParsedRequest? {
        guard request.chainId.namespace == WCNNamespace.eip155,
              [WCNEvmTransactionParsed.sendMethod, WCNEvmTransactionParsed.signMethod].contains(request.method)
        else {
            return nil
        }

        guard let chainId = Int(request.chainId.reference),
              let blockchain = evmBlockchainManager.blockchain(chainId: chainId),
              let baseToken = try? coinManager.token(query: .init(blockchainType: blockchain.type, tokenType: .native))
        else {
            throw ParsingError.unsupportedChain(request.chainId.absoluteString)
        }

        let transaction = try WCNEvmTransaction.parse(params: request.params)
        let kitWrapper = accountManager.activeAccount.flatMap { evmBlockchainManager.kitWrapper(chainId: chainId, account: $0) }
        let swapInfo = kitWrapper.flatMap { Self.swapInfo(decoration: $0.evmKit.decorate(transactionData: transaction.transactionData)) }

        return WCNEvmTransactionParsed(request: request, transaction: transaction, blockchainType: blockchain.type, baseToken: baseToken, swapInfo: swapInfo)
    }

    private static func swapInfo(decoration: TransactionDecoration?) -> WCNSwapInfo? {
        switch decoration {
        case let decoration as OneInchSwapDecoration:
            return WCNSwapInfo(provider: .oneInch, tokenInIsNative: isNative(decoration.tokenIn))
        case let decoration as OneInchUnoswapDecoration:
            return WCNSwapInfo(provider: .oneInch, tokenInIsNative: isNative(decoration.tokenIn))
        case let decoration as SwapDecoration:
            return WCNSwapInfo(provider: .uniswap, tokenInIsNative: isNative(decoration.tokenIn))
        default:
            return nil
        }
    }

    private static func isNative(_ token: OneInchDecoration.Token) -> Bool {
        if case .evmCoin = token { return true }
        return false
    }

    private static func isNative(_ token: SwapDecoration.Token) -> Bool {
        if case .evmCoin = token { return true }
        return false
    }
}

extension WCNEvmTransactionParser {
    enum ParsingError: Error, Equatable {
        case unsupportedChain(String)
    }
}
