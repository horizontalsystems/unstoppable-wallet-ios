import Foundation
import MarketKit

class OpenCryptoPayManager {
    let provider: OpenCryptoPayProvider
    let broadcasterFactory: OpenCryptoPayBroadcasterFactory
    private let walletManager: WalletManager
    private let accountManager: AccountManager

    private var currentTask: Task<OpenCryptoPayPayment, Swift.Error>?

    init(provider: OpenCryptoPayProvider, walletManager: WalletManager, accountManager: AccountManager, broadcasterFactory: OpenCryptoPayBroadcasterFactory) {
        self.provider = provider
        self.walletManager = walletManager
        self.accountManager = accountManager
        self.broadcasterFactory = broadcasterFactory
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

    func resolve(wallet: Wallet, against payment: OpenCryptoPayPayment) async throws -> SendData {
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
        let options = try OpenCryptoPayPayment.Validator.validate(txDetails: txDetails, against: payment, wallet: wallet)

        guard let address = options.address else {
            throw OpenCryptoPayManager.Error.malformedTxUri
        }
        let resolvedAddress = ResolvedAddress(address: address, issueTypes: [])
        guard let preSend = SendHandlerFactory.preSendHandler(wallet: wallet, address: resolvedAddress) else {
            throw OpenCryptoPayManager.Error.malformedTxUri
        }

        let amount = options.amount?.humanReadable(decimals: wallet.token.decimals) ?? 0
        let result = preSend.sendData(amount: amount, address: address, memo: options.memo)
        guard case let .valid(inner) = result else {
            throw OpenCryptoPayManager.Error.malformedTxUri
        }
        return .openCryptoPay(payment: payment, entry: entry, inner: inner)
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
            guard let chain = broadcasterFactory.supportedChains[transferAmount.method] else {
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
