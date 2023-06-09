import Foundation
import TronKit
import MarketKit
import BigInt

class TronTransactionConverter {
    private let coinManager: CoinManager
    private let tronKitWrapper: TronKitWrapper
    private let evmLabelManager: EvmLabelManager
    private let source: TransactionSource
    private let baseToken: MarketKit.Token

    init(source: TransactionSource, baseToken: MarketKit.Token, coinManager: CoinManager, tronKitWrapper: TronKitWrapper, evmLabelManager: EvmLabelManager) {
        self.coinManager = coinManager
        self.tronKitWrapper = tronKitWrapper
        self.evmLabelManager = evmLabelManager
        self.source = source
        self.baseToken = baseToken
    }

    private var tronKit: TronKit.Kit {
        tronKitWrapper.tronKit
    }

    private func convertAmount(amount: BigUInt, decimals: Int, sign: FloatingPointSign) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: sign, exponent: -decimals, significand: significand)
    }

    private func baseCoinValue(value: Int, sign: FloatingPointSign) -> TransactionValue {
        let amount = convertAmount(amount: BigUInt(value), decimals: baseToken.decimals, sign: sign)
        return .coinValue(token: baseToken, value: amount)
    }

    private func eip20Value(tokenAddress: TronKit.Address, value: BigUInt, sign: FloatingPointSign, tokenInfo: TokenInfo?) -> TransactionValue {
        let query = TokenQuery(blockchainType: tronKitWrapper.blockchainType, tokenType: .eip20(address: tokenAddress.base58))

        if let token = try? coinManager.token(query: query) {
            let value = convertAmount(amount: value, decimals: token.decimals, sign: sign)
            return .coinValue(token: token, value: value)
        } else if let tokenInfo = tokenInfo {
            let value = convertAmount(amount: value, decimals: tokenInfo.tokenDecimal, sign: sign)
            return .tokenValue(tokenName: tokenInfo.tokenName, tokenCode: tokenInfo.tokenSymbol, tokenDecimals: tokenInfo.tokenDecimal, value: value)
        }

        return .rawValue(value: value)
    }

    private func transferEvents(incomingTrc20Transfers: [Trc20TransferEvent]) -> [TronContractCallTransactionRecord.TransferEvent] {
        incomingTrc20Transfers.map { transfer in
            TronContractCallTransactionRecord.TransferEvent(
                address: transfer.from.base58,
                value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .plus, tokenInfo: transfer.tokenInfo)
            )
        }
    }

    private func transferEvents(outgoingTrc20Transfers: [Trc20TransferEvent]) -> [TronContractCallTransactionRecord.TransferEvent] {
        outgoingTrc20Transfers.map { transfer in
            TronContractCallTransactionRecord.TransferEvent(
                address: transfer.to.base58,
                value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .minus, tokenInfo: transfer.tokenInfo)
            )
        }
    }

    private func transferEvents(internalTransactions: [InternalTransaction]) -> [TronContractCallTransactionRecord.TransferEvent] {
        internalTransactions.map { internalTransaction in
            TronContractCallTransactionRecord.TransferEvent(
                address: internalTransaction.from.base58,
                value: baseCoinValue(value: internalTransaction.value, sign: .plus)
            )
        }
    }

    private func transferEvents(contractAddress: TronKit.Address, value: Int) -> [TronContractCallTransactionRecord.TransferEvent] {
        guard value != 0 else {
            return []
        }

        let event = TronContractCallTransactionRecord.TransferEvent(
            address: contractAddress.base58,
            value: baseCoinValue(value: value, sign: .minus)
        )

        return [event]
    }

}

extension TronTransactionConverter {

    func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> TronTransactionRecord {
        let transaction = fullTransaction.transaction

        switch fullTransaction.decoration {
            case let decoration as NativeTransactionDecoration:
                switch decoration.contract {
                    case let transfer as TransferContract:
                        if transfer.ownerAddress != tronKit.address {
                            return TronIncomingTransactionRecord(
                                source: source,
                                transaction: transaction,
                                baseToken: baseToken,
                                from: transfer.ownerAddress.base58,
                                value: baseCoinValue(value: transfer.amount, sign: .plus),
                                spam: transfer.amount < 10
                            )
                        } else {
                            return TronOutgoingTransactionRecord(
                                source: source,
                                transaction: transaction,
                                baseToken: baseToken,
                                to: transfer.toAddress.base58,
                                value: baseCoinValue(value: transfer.amount, sign: .minus),
                                sentToSelf: transfer.toAddress == tronKit.address
                            )
                        }

                    default:
                        return TronTransactionRecord(
                            source: source,
                            transaction: transaction,
                            baseToken: baseToken,
                            ownTransaction: transaction.ownTransaction(ownAddress: tronKit.address)
                        )
                }
                
            case let decoration as OutgoingEip20Decoration:
                return TronOutgoingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    to: decoration.to.base58,
                    value: eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .minus, tokenInfo: decoration.tokenInfo),
                    sentToSelf: decoration.sentToSelf
                )

            case let decoration as ApproveEip20Decoration:
                return TronApproveTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    spender: decoration.spender.base58,
                    value: eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .plus, tokenInfo: nil)
                )

            case let decoration as UnknownTransactionDecoration:
                let address = tronKit.address

                let internalTransactions = decoration.internalTransactions.filter { $0.to == address }

                let trc0Transfers = decoration.events.compactMap { $0 as? Trc20TransferEvent }
                let incomingTrc20Transfers = trc0Transfers.filter { $0.to == address && $0.from != address }
                let outgoingTrc20Transfers = trc0Transfers.filter { $0.from == address }

                if decoration.fromAddress == address, let contractAddress = decoration.toAddress {
                    let value = decoration.value ?? 0

                    return TronContractCallTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseToken: baseToken,
                        contractAddress: contractAddress.base58,
                        method: decoration.data.flatMap { evmLabelManager.methodLabel(input: $0) },
                        incomingEvents: transferEvents(internalTransactions: internalTransactions) + transferEvents(incomingTrc20Transfers: incomingTrc20Transfers),
                        outgoingEvents: transferEvents(contractAddress: contractAddress, value: value) + transferEvents(outgoingTrc20Transfers: outgoingTrc20Transfers)
                    )
                } else if decoration.fromAddress != address && decoration.toAddress != address {
                    return TronExternalContractCallTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseToken: baseToken,
                        incomingEvents: transferEvents(internalTransactions: internalTransactions) + transferEvents(incomingTrc20Transfers: incomingTrc20Transfers),
                        outgoingEvents: transferEvents(outgoingTrc20Transfers: outgoingTrc20Transfers)
                    )
                }

            default: ()
        }

        return TronTransactionRecord(
            source: source,
            transaction: transaction,
            baseToken: baseToken,
            ownTransaction: transaction.ownTransaction(ownAddress: tronKit.address)
        )
    }

}
