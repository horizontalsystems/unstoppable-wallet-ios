import Foundation
import EthereumKit
import Erc20Kit
import UniswapKit
import OneInchKit
import MarketKit
import BigInt

class EvmTransactionConverter {
    private let coinManager: CoinManager
    private let evmKitWrapper: EvmKitWrapper
    private let source: TransactionSource
    private let baseCoin: PlatformCoin

    init(source: TransactionSource, baseCoin: PlatformCoin, coinManager: CoinManager, evmKitWrapper: EvmKitWrapper) {
        self.coinManager = coinManager
        self.evmKitWrapper = evmKitWrapper
        self.source = source
        self.baseCoin = baseCoin
    }

    private var evmKit: EthereumKit.Kit {
        evmKitWrapper.evmKit
    }

    private func convertAmount(amount: BigUInt, decimals: Int, sign: FloatingPointSign) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: sign, exponent: -decimals, significand: significand)
    }

    private func baseCoinValue(value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        let amount = convertAmount(amount: value, decimals: baseCoin.decimals, sign: sign)
        return .coinValue(platformCoin: baseCoin, value: amount)
    }

    private func eip20Value(tokenAddress: EthereumKit.Address, value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        let coinType = evmKitWrapper.blockchain.evm20CoinType(address: tokenAddress.hex)

        if let platformCoin = try? coinManager.platformCoin(coinType: coinType) {
            let value = convertAmount(amount: value, decimals: platformCoin.decimals, sign: sign)
            return .coinValue(platformCoin: platformCoin, value: value)
        }

        return .rawValue(value: value)
    }

    private func convertToAmount(token: SwapDecoration.Token, amount: SwapDecoration.Amount, sign: FloatingPointSign) -> SwapTransactionRecord.Amount {
        switch amount {
        case .exact(let value): return .exact(value: convertToTransactionValue(token: token, value: value, sign: sign))
        case .extremum(let value): return .extremum(value: convertToTransactionValue(token: token, value: value, sign: sign))
        }
    }

    private func convertToTransactionValue(token: SwapDecoration.Token, value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        switch token {
        case .evmCoin: return baseCoinValue(value: value, sign: sign)
        case .eip20Coin(let tokenAddress): return eip20Value(tokenAddress: tokenAddress, value: value, sign: sign)
        }
    }

    private func convertToAmount(token: OneInchDecoration.Token, amount: OneInchDecoration.Amount, sign: FloatingPointSign) -> SwapTransactionRecord.Amount {
        switch amount {
        case .exact(let value): return .exact(value: convertToTransactionValue(token: token, value: value, sign: sign))
        case .extremum(let value): return .extremum(value: convertToTransactionValue(token: token, value: value, sign: sign))
        }
    }

    private func convertToTransactionValue(token: OneInchDecoration.Token, value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        switch token {
        case .evmCoin: return baseCoinValue(value: value, sign: sign)
        case .eip20Coin(let tokenAddress): return eip20Value(tokenAddress: tokenAddress, value: value, sign: sign)
        }
    }

    private func transferEvents(internalTransactions: [InternalTransaction]) -> [ContractCallTransactionRecord.TransferEvent] {
        internalTransactions.map { internalTransaction in
            ContractCallTransactionRecord.TransferEvent(
                    address: internalTransaction.from.eip55,
                    value: baseCoinValue(value: internalTransaction.value, sign: .plus)
            )
        }
    }

    private func transferEvents(incomingTransfers: [TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        incomingTransfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.from.eip55,
                    value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .plus)
            )
        }
    }

    private func transferEvents(outgoingTransfers: [TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        outgoingTransfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.to.eip55,
                    value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .minus)
            )
        }
    }

}

extension EvmTransactionConverter {

    func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> EvmTransactionRecord {
        let transaction = fullTransaction.transaction

        switch fullTransaction.decoration {
        case is ContractCreationDecoration:
            return ContractCreationTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin
            )

        case let decoration as IncomingDecoration:
            return EvmIncomingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    from: decoration.from.eip55,
                    value: baseCoinValue(value: decoration.value, sign: .plus)
            )

        case let decoration as OutgoingDecoration:
            return EvmOutgoingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    to: decoration.to.eip55,
                    value: baseCoinValue(value: decoration.value, sign: .minus),
                    sentToSelf: decoration.sentToSelf
            )

        case let decoration as OutgoingEip20Decoration:
            return EvmOutgoingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    to: decoration.to.eip55,
                    value: eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .minus),
                    sentToSelf: decoration.sentToSelf
            )

        case let decoration as ApproveEip20Decoration:
            return ApproveTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    spender: decoration.spender.eip55,
                    value: eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .plus)
            )

        case let decoration as SwapDecoration:
            return SwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    exchangeAddress: decoration.contractAddress.eip55,
                    amountIn: convertToAmount(token: decoration.tokenIn, amount: decoration.amountIn, sign: .minus),
                    amountOut: convertToAmount(token: decoration.tokenOut, amount: decoration.amountOut, sign: .plus),
                    foreignRecipient: decoration.recipient != nil
            )

        case let decoration as OneInchSwapDecoration:
            return SwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    exchangeAddress: decoration.contractAddress.eip55,
                    amountIn: .exact(value: convertToTransactionValue(token: decoration.tokenIn, value: decoration.amountIn, sign: .minus)),
                    amountOut: convertToAmount(token: decoration.tokenOut, amount: decoration.amountOut, sign: .plus),
                    foreignRecipient: decoration.recipient != nil
            )

        case let decoration as OneInchUnoswapDecoration:
            return SwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    exchangeAddress: decoration.contractAddress.eip55,
                    amountIn: .exact(value: convertToTransactionValue(token: decoration.tokenIn, value: decoration.amountIn, sign: .minus)),
                    amountOut: decoration.tokenOut.map { convertToAmount(token: $0, amount: decoration.amountOut, sign: .plus) },
                    foreignRecipient: false
            )

        case let decoration as OneInchUnknownSwapDecoration:
            let address = evmKit.address

            let internalTransactions = decoration.internalTransactions.filter { $0.to == address }

            let transferEventInstances = decoration.eventInstances.compactMap { $0 as? TransferEventInstance }
            let incomingTransfers = transferEventInstances.filter { $0.to == address && $0.from != address }
            let outgoingTransfers = transferEventInstances.filter { $0.from == address }

            return UnknownSwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    exchangeAddress: decoration.contractAddress.eip55,
                    value: baseCoinValue(value: decoration.value, sign: .minus),
                    internalTransactionEvents: transferEvents(internalTransactions: internalTransactions),
                    incomingEip20Events: transferEvents(incomingTransfers: incomingTransfers),
                    outgoingEip20Events: transferEvents(outgoingTransfers: outgoingTransfers)
            )

        case let decoration as UnknownTransactionDecoration:
            let address = evmKit.address

            let internalTransactions = decoration.internalTransactions.filter { $0.to == address }

            let transferEventInstances = decoration.eventInstances.compactMap { $0 as? TransferEventInstance }
            let incomingTransfers = transferEventInstances.filter { $0.to == address && $0.from != address }
            let outgoingTransfers = transferEventInstances.filter { $0.from == address }

            if transaction.from != address && internalTransactions.count == 1 && transferEventInstances.isEmpty {
                let internalTx = internalTransactions[0]

                return EvmIncomingTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseCoin: baseCoin,
                        from: internalTx.from.eip55,
                        value: baseCoinValue(value: internalTx.value, sign: .plus)
                )
            } else if transaction.from != address && incomingTransfers.count == 1 && internalTransactions.isEmpty && outgoingTransfers.isEmpty {
                let transfer = incomingTransfers[0]

                return EvmIncomingTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseCoin: baseCoin,
                        from: transfer.from.eip55,
                        value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .plus)
                )
            } else if transaction.from != address && outgoingTransfers.count == 1 && internalTransactions.isEmpty && incomingTransfers.isEmpty {
                let transfer = outgoingTransfers[0]

                return EvmOutgoingTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseCoin: baseCoin,
                        to: transfer.to.eip55,
                        value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .minus),
                        sentToSelf: transfer.to == address
                )
            } else {
                return ContractCallTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseCoin: baseCoin,
                        contractAddress: transaction.to?.eip55,
                        method: nil,
                        value: transaction.value.map { baseCoinValue(value: $0, sign: .minus) },
                        internalTransactionEvents: transferEvents(internalTransactions: internalTransactions),
                        incomingEip20Events: transferEvents(incomingTransfers: incomingTransfers),
                        outgoingEip20Events: transferEvents(outgoingTransfers: outgoingTransfers)
                )
            }

        default:
            return EvmTransactionRecord(source: source, transaction: transaction, baseCoin: baseCoin)
        }
    }

}
