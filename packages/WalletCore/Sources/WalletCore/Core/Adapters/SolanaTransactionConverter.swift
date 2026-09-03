import Foundation
import MarketKit
import SolanaKit

class SolanaTransactionConverter {
    // Display labels for the swap programs SolanaKit recognizes (`Transaction.programIds`).
    // Mirrors the EVM flow, where the exchange contract address maps to a label ("1inch v5").
    private static let swapProgramLabels: [String: String] = [
        KnownPrograms.jupiterV6: "Jupiter",
        KnownPrograms.lifi: "LI.FI",
        KnownPrograms.dflow: "DFlow",
    ]

    // ≈ one account's rent: classic ATA (165 bytes) ~0.00204 SOL, Token-2022 with extensions
    // 0.00207–0.00220 (mainnet 0.00210888 for a Pump.fun ATA). Applied to the NET SOL change, so a
    // real payment bundled with a create pushes past the bound and stays visible.
    private static let maxSolRent = Decimal(string: "0.0023")!

    private let userAddress: String
    private let source: TransactionSource
    private let baseToken: Token
    private let coinManager: CoinManager

    init(userAddress: String, source: TransactionSource, baseToken: Token, coinManager: CoinManager) {
        self.userAddress = userAddress
        self.source = source
        self.baseToken = baseToken
        self.coinManager = coinManager
    }

    // The display label of the first recognized swap program this transaction invoked, or nil.
    private func swapExchangeName(transaction: SolanaKit.Transaction) -> String? {
        guard let programIds = transaction.programIds else { return nil }
        return programIds.split(separator: " ").lazy.compactMap { Self.swapProgramLabels[String($0)] }.first
    }

    // The swap-relevant leg of one side: the SPL transfer when a native-SOL leg rides along
    // (token-account rent), otherwise the single/first leg (a genuinely-SOL swap side).
    private func primaryTransfer(among transfers: [SolanaTransactionRecord.Transfer]) -> SolanaTransactionRecord.Transfer? {
        transfers.first { $0.value.token != baseToken } ?? transfers.first
    }

    // A side that is exactly one token leg plus small SOL legs (each ≤ maxSolRent) is one logical
    // transfer plus token-account rent — reduce it to the token leg. createdTokenAccount decides:
    // true → rent, false → real SOL transfer (kept), nil (row synced before the flag) → treat as rent.
    private func collapseTokenWithSolRent(_ transfers: [SolanaTransactionRecord.Transfer], createdTokenAccount: Bool?) -> [SolanaTransactionRecord.Transfer] {
        guard transfers.count > 1 else { return transfers }

        let solLegs = transfers.filter { $0.value.token == baseToken }
        let tokenLegs = transfers.filter { $0.value.token != baseToken }

        guard tokenLegs.count == 1, !solLegs.isEmpty else { return transfers }
        guard solLegs.allSatisfy({ abs($0.value.value) <= Self.maxSolRent }) else { return transfers }

        return (createdTokenAccount ?? true) ? tokenLegs : transfers
    }

    private func convertAmount(rawAmount: Decimal, decimals: Int, sign: FloatingPointSign) -> Decimal {
        guard rawAmount != 0 else {
            return 0
        }
        return Decimal(sign: sign, exponent: -decimals, significand: rawAmount)
    }

    func transactionRecord(fullTransaction: FullTransaction) -> SolanaTransactionRecord {
        let transaction = fullTransaction.transaction
        var incomingTransfers = [SolanaTransactionRecord.Transfer]()
        var outgoingTransfers = [SolanaTransactionRecord.Transfer]()

        // Handle SOL transfer
        if let rawAmount = transaction.decimalAmount {
            if transaction.from == userAddress {
                let value = convertAmount(rawAmount: rawAmount, decimals: baseToken.decimals, sign: .minus)
                let appValue = AppValue(token: baseToken, value: value)
                outgoingTransfers.append(SolanaTransactionRecord.Transfer(address: transaction.to, value: appValue))
            } else if transaction.to == userAddress {
                let value = convertAmount(rawAmount: rawAmount, decimals: baseToken.decimals, sign: .plus)
                let appValue = AppValue(token: baseToken, value: value)
                incomingTransfers.append(SolanaTransactionRecord.Transfer(address: transaction.from, value: appValue))
            }
        }

        // Handle SPL token transfers
        for fullTokenTransfer in fullTransaction.tokenTransfers {
            let tokenTransfer = fullTokenTransfer.tokenTransfer
            let mintAccount = fullTokenTransfer.mintAccount
            let query = TokenQuery(blockchainType: .solana, tokenType: .spl(address: tokenTransfer.mintAddress))
            let sign: FloatingPointSign = tokenTransfer.incoming ? .plus : .minus

            let appValue: AppValue
            if let token = try? coinManager.token(query: query) {
                let value = convertAmount(rawAmount: tokenTransfer.decimalAmount, decimals: token.decimals, sign: sign)
                appValue = AppValue(token: token, value: value)
            } else if mintAccount.isNft {
                let nftValue = convertAmount(rawAmount: tokenTransfer.decimalAmount, decimals: 0, sign: sign)
                appValue = AppValue(
                    nftUid: .solana(contractAddress: mintAccount.address, tokenId: ""),
                    tokenName: mintAccount.name,
                    tokenSymbol: mintAccount.symbol,
                    value: nftValue
                )
            } else {
                appValue = AppValue(value: convertAmount(rawAmount: tokenTransfer.decimalAmount, decimals: 0, sign: sign))
            }

            if tokenTransfer.incoming {
                incomingTransfers.append(SolanaTransactionRecord.Transfer(address: transaction.from, value: appValue))
            } else {
                outgoingTransfers.append(SolanaTransactionRecord.Transfer(address: transaction.to, value: appValue))
            }
        }

        // A recognized DEX interaction (via SolanaKit KnownPrograms) renders as a swap — we key purely
        // on the invoked program. Same-chain swaps (Jupiter) carry legs on both sides; a CROSS-CHAIN
        // LI.FI swap FROM Solana carries only the OUTGOING side (the bought asset lands on another
        // chain); a pending swap carries no legs yet (the kit stores no balance changes until
        // confirmation) — all are swaps. A side can carry a spurious SOL leg next to the real SPL one
        // (tx fee / token-account rent), so each side prefers its non-SOL leg via `primaryTransfer`
        // (`valueIn`/`valueOut` are nil when that side has no leg).
        if let exchangeName = swapExchangeName(transaction: transaction) {
            return SolanaSwapTransactionRecord(
                transaction: transaction,
                baseToken: baseToken,
                source: source,
                exchangeName: exchangeName,
                valueIn: primaryTransfer(among: outgoingTransfers)?.value,
                valueOut: primaryTransfer(among: incomingTransfers)?.value
            )
        }

        // A plain SPL send/receive also moves a little SOL for token-account rent (when the
        // recipient's account has to be created) — without the collapse such sends fall through
        // to "Unknown Transaction".
        let effectiveIncoming = collapseTokenWithSolRent(incomingTransfers, createdTokenAccount: transaction.createdTokenAccount)
        let effectiveOutgoing = collapseTokenWithSolRent(outgoingTransfers, createdTokenAccount: transaction.createdTokenAccount)

        // Classify the transaction
        if effectiveIncoming.count == 1, effectiveOutgoing.isEmpty {
            let transfer = effectiveIncoming[0]
            return SolanaIncomingTransactionRecord(
                transaction: transaction,
                baseToken: baseToken,
                source: source,
                from: transfer.address,
                value: transfer.value
            )
        } else if effectiveIncoming.isEmpty, effectiveOutgoing.count == 1 {
            let transfer = effectiveOutgoing[0]
            return SolanaOutgoingTransactionRecord(
                transaction: transaction,
                baseToken: baseToken,
                source: source,
                to: transfer.address,
                value: transfer.value,
                sentToSelf: transfer.address == userAddress
            )
        } else {
            return SolanaUnknownTransactionRecord(
                transaction: transaction,
                baseToken: baseToken,
                source: source,
                incomingTransfers: incomingTransfers,
                outgoingTransfers: outgoingTransfers
            )
        }
    }
}
