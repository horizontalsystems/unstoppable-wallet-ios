import Foundation
import MarketKit

class OpenCryptoPayManager {
    private static let methodToBlockchainType: [String: BlockchainType] = [
        "Bitcoin": .bitcoin,
        "Ethereum": .ethereum,
        "BinanceSmartChain": .binanceSmartChain,
        "Polygon": .polygon,
        "Arbitrum": .arbitrumOne,
        "Optimism": .optimism,
        "Base": .base,
        "Tron": .tron,
        "Solana": .solana,
        "Ton": .ton,
        "Stellar": .stellar,
    ]

    private let provider: OpenCryptoPayProvider
    private let walletManager: WalletManager
    private let accountManager: AccountManager

    private var currentTask: Task<OpenCryptoPayPayment, Swift.Error>?

    static func blockchainType(forMethod method: String) -> BlockchainType? {
        methodToBlockchainType[method]
    }

    init(provider: OpenCryptoPayProvider, walletManager: WalletManager, accountManager: AccountManager) {
        self.provider = provider
        self.walletManager = walletManager
        self.accountManager = accountManager
    }

    func startPayment(url: URL) async throws -> OpenCryptoPayPayment {
        currentTask?.cancel()

        let task = Task { [weak self] () -> OpenCryptoPayPayment in
            guard let self else { throw CancellationError() }
            let payment = try await fetchAndBuild(url: url)
            try OpenCryptoPayPayment.Validator.validateSession(payment)
            return payment
        }
        currentTask = task

        do {
            return try await task.value
        } catch let err as OpenCryptoPayManager.Error {
            throw err
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw OpenCryptoPayManager.Error.network(error)
        }
    }

    /// Resolver used by OpenCryptoPayEventHandler. Hides provider from outside; enforces account + wallet guards.
    func resolve(wallet: Wallet, against payment: OpenCryptoPayPayment) async throws -> SendTokenListViewModel.SendOptions {
        guard accountManager.activeAccount?.id == payment.capturedAccountId else {
            throw OpenCryptoPayManager.Error.accountChanged
        }
        guard walletManager.activeWallets.contains(wallet) else {
            throw OpenCryptoPayManager.Error.accountChanged
        }
        guard let entry = payment.entry(for: wallet) else {
            throw OpenCryptoPayManager.Error.chainMismatch
        }
        let txDetails = try await provider.fetchTransactionDetails(
            callback: payment.callback,
            quoteId: payment.quoteId,
            method: entry.method,
            asset: entry.asset
        )
        return try OpenCryptoPayPayment.Validator.validate(txDetails: txDetails, against: payment, wallet: wallet)
    }

    private func fetchAndBuild(url: URL) async throws -> OpenCryptoPayPayment {
        let apiUrl = try OpenCryptoPayUrl.decodeLnurl(url)
        let response = try await provider.fetchPaymentDetails(url: apiUrl)

        guard let accountId = accountManager.activeAccount?.id else {
            throw OpenCryptoPayManager.Error.noSupportedMethod
        }

        let userWallets = walletManager.activeWallets
        var entries: [OpenCryptoPayPayment.Entry] = []

        for transferAmount in response.transferAmounts where transferAmount.available {
            guard let chain = Self.blockchainType(forMethod: transferAmount.method) else {
                continue
            }

            for asset in transferAmount.assets {
                for token in resolveTokens(asset: asset, chain: chain, userWallets: userWallets) {
                    // BTC may have up to 4 wallets (bip44/49/84/86); BCH has 2 (address types).
                    // Emit one Entry per Token so the user can pay from any of them.
                    entries.append(.init(
                        id: "\(transferAmount.method):\(asset.asset):\(token.type.id)",
                        method: transferAmount.method,
                        blockchainType: chain,
                        asset: asset.asset,
                        displayAmount: asset.amount,
                        token: token
                    ))
                }
            }
        }

        return OpenCryptoPayPayment(
            quoteId: response.quote.id,
            quoteExpirationDate: response.quote.expiration,
            callback: response.callback,
            recipient: .init(
                name: response.recipient.name,
                mail: response.recipient.mail,
                website: response.recipient.website
            ),
            entries: entries,
            capturedAccountId: accountId
        )
    }

    private func resolveTokens(asset: OpenCryptoPayProvider.Models.Asset, chain: BlockchainType, userWallets: [Wallet]) -> [Token] {
        let symbol = asset.asset.uppercased()
        var seen = Set<String>()
        var result: [Token] = []
        for wallet in userWallets {
            let token = wallet.token
            guard token.blockchainType == chain, token.coin.code.uppercased() == symbol else { continue }
            if seen.insert(token.type.id).inserted {
                result.append(token)
            }
        }
        return result
    }
}

extension OpenCryptoPayManager {
    enum Error: LocalizedError {
        case invalidUrl
        case invalidLnurl
        case noSupportedMethod
        case quoteExpired
        case malformedTxUri
        case amountMismatch
        case unsupportedTxParameter(String)
        case chainMismatch
        case accountChanged
        case network(Swift.Error)

        var errorDescription: String? {
            switch self {
            case .invalidUrl: return "open_crypto_pay.error.invalid_url".localized
            case .invalidLnurl: return "open_crypto_pay.error.invalid_lnurl".localized
            case .noSupportedMethod: return "open_crypto_pay.error.no_supported_method".localized
            case .quoteExpired: return "open_crypto_pay.error.quote_expired".localized
            case .malformedTxUri: return "open_crypto_pay.error.malformed_tx_uri".localized
            case .amountMismatch: return "open_crypto_pay.error.amount_mismatch".localized
            case .unsupportedTxParameter: return "open_crypto_pay.error.unsupported_parameter".localized
            case .chainMismatch: return "open_crypto_pay.error.chain_mismatch".localized
            case .accountChanged: return "open_crypto_pay.error.account_changed".localized
            case let .network(err): return err.localizedDescription
            }
        }
    }
}
