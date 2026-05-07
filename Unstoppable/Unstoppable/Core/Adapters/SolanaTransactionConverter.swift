import Foundation
import MarketKit
import SolanaKit

class SolanaTransactionConverter {
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
                incomingTransfers.append(SolanaTransactionRecord.Transfer(address: nil, value: appValue))
            } else {
                outgoingTransfers.append(SolanaTransactionRecord.Transfer(address: nil, value: appValue))
            }
        }

        // Classify the transaction
        if incomingTransfers.count == 1, outgoingTransfers.isEmpty {
            let transfer = incomingTransfers[0]
            return SolanaIncomingTransactionRecord(
                transaction: transaction,
                baseToken: baseToken,
                source: source,
                from: transfer.address,
                value: transfer.value
            )
        } else if incomingTransfers.isEmpty, outgoingTransfers.count == 1 {
            let transfer = outgoingTransfers[0]
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
