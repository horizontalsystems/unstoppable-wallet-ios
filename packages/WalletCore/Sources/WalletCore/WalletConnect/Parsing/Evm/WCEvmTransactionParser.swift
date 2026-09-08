import EvmKit
import MarketKit
import OneInchKit
import UniswapKit
import WalletConnectSign

class WCEvmTransactionParser: IWCParser {
    private let evmBlockchainManager: EvmBlockchainManager
    private let coinManager: CoinManager
    private let accountManager: AccountManager

    init(evmBlockchainManager: EvmBlockchainManager, coinManager: CoinManager, accountManager: AccountManager) {
        self.evmBlockchainManager = evmBlockchainManager
        self.coinManager = coinManager
        self.accountManager = accountManager
    }

    func parse(request: Request) throws -> WCRequestPayload? {
        guard request.chainId.namespace == WCNamespace.eip155,
              [WCEvmTransactionPayload.sendMethod, WCEvmTransactionPayload.signMethod].contains(request.method)
        else {
            return nil
        }

        guard let chainId = Int(request.chainId.reference),
              let blockchain = evmBlockchainManager.blockchain(chainId: chainId),
              let baseToken = try? coinManager.token(query: .init(blockchainType: blockchain.type, tokenType: .native))
        else {
            throw ParsingError.unsupportedChain(request.chainId.absoluteString)
        }

        let transaction = try WCEvmTransaction.parse(params: request.params)
        let kitWrapper = accountManager.activeAccount.flatMap { evmBlockchainManager.kitWrapper(chainId: chainId, account: $0) }
        let swapInfo = kitWrapper.flatMap { Self.swapInfo(decoration: $0.evmKit.decorate(transactionData: transaction.transactionData)) }

        return WCEvmTransactionPayload(request: request, transaction: transaction, blockchainType: blockchain.type, baseToken: baseToken, swapInfo: swapInfo)
    }

    private static func swapInfo(decoration: TransactionDecoration?) -> WCSwapInfo? {
        switch decoration {
        case let decoration as OneInchSwapDecoration:
            return WCSwapInfo(provider: .oneInch, tokenInIsNative: isNative(decoration.tokenIn))
        case let decoration as OneInchUnoswapDecoration:
            return WCSwapInfo(provider: .oneInch, tokenInIsNative: isNative(decoration.tokenIn))
        case let decoration as SwapDecoration:
            return WCSwapInfo(provider: .uniswap, tokenInIsNative: isNative(decoration.tokenIn))
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

extension WCEvmTransactionParser {
    enum ParsingError: Error, Equatable {
        case unsupportedChain(String)
    }
}
