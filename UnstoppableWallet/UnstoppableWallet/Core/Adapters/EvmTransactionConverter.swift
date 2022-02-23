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

    private func eip20Value(tokenAddress: EthereumKit.Address, value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        let coinType = evmKitWrapper.blockchain.evm20CoinType(address: tokenAddress.hex)

        if let platformCoin = try? coinManager.platformCoin(coinType: coinType) {
            let value = convertAmount(amount: value, decimals: platformCoin.decimals, sign: sign)
            return .coinValue(platformCoin: platformCoin, value: value)
        }

        return .rawValue(coinType: coinType, value: value)
    }

    private func convertToTransactionValue(token: SwapMethodDecoration.Token, value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        switch token {
        case .evmCoin:
            let value = convertAmount(amount: value, decimals: baseCoin.decimals, sign: sign)
            return .coinValue(platformCoin: baseCoin, value: value)

        case .eip20Coin(let tokenAddress):
            return eip20Value(tokenAddress: tokenAddress, value: value, sign: sign)
        }
    }

    private func convertToTransactionValue(token: OneInchMethodDecoration.Token, value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        switch token {
        case .evmCoin:
            let value = convertAmount(amount: value, decimals: baseCoin.decimals, sign: sign)
            return .coinValue(platformCoin: baseCoin, value: value)

        case .eip20Coin(let tokenAddress):
            return eip20Value(tokenAddress: tokenAddress, value: value, sign: sign)
        }
    }

    private func internalTransactions(from fullTransaction: FullTransaction) -> [ContractCallTransactionRecord.AddressTransactionValue] {
        fullTransaction.internalTransactions.compactMap { internalTransaction in
            guard internalTransaction.to == evmKit.address else {
                return nil
            }

            let amount = convertAmount(amount: internalTransaction.value, decimals: baseCoin.decimals, sign: .plus)
            return (address: internalTransaction.from.eip55, value: .coinValue(platformCoin: baseCoin, value: amount))
        }
    }

    private func incomingEip20Events(from fullTransaction: FullTransaction) -> [ContractCallTransactionRecord.AddressTransactionValue] {
        fullTransaction.eventDecorations.compactMap { event in
            guard let decoration = event as? TransferEventDecoration, decoration.to == evmKit.address else {
                return nil
            }

            let value = eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .plus)
            return (address: decoration.from.eip55, value: value)
        }
    }

    private func outgoingEip20Events(from fullTransaction: FullTransaction) -> [ContractCallTransactionRecord.AddressTransactionValue] {
        fullTransaction.eventDecorations.compactMap { event in
            guard let decoration = event as? TransferEventDecoration, decoration.from == evmKit.address else {
                return nil
            }

            let value = eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .minus)
            return (address: decoration.to.eip55, value: value)
        }
    }

    private func convertMyCall(methodDecoration: ContractMethodDecoration, fullTransaction: FullTransaction, to: EthereumKit.Address) -> EvmTransactionRecord {
        switch methodDecoration {
        case let decoration as TransferMethodDecoration:
            return EvmOutgoingTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    to: decoration.to.eip55,
                    value: eip20Value(tokenAddress: to, value: decoration.value, sign: .minus),
                    sentToSelf: decoration.to == fullTransaction.transaction.from
            )

        case let decoration as ApproveMethodDecoration:
            return ApproveTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    spender: decoration.spender.eip55,
                    value: eip20Value(tokenAddress: to, value: decoration.value, sign: .plus)
            )

        case let decoration as SwapMethodDecoration:
            let resolvedAmountIn: BigUInt
            let resolvedAmountOut: BigUInt

            if fullTransaction.failed {
                resolvedAmountIn = 0
                resolvedAmountOut = 0
            } else {
                switch decoration.trade {
                    case .exactIn(let amountIn, let amountOutMin, let amountOut):
                        resolvedAmountIn = amountIn
                        resolvedAmountOut = amountOut ?? amountOutMin

                    case .exactOut(let amountOut, let amountInMax, let amountIn):
                        resolvedAmountIn = amountIn ?? amountInMax
                        resolvedAmountOut = amountOut
                }
            }

            return SwapTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    valueIn: convertToTransactionValue(token: decoration.tokenIn, value: resolvedAmountIn, sign: .minus),
                    valueOut: convertToTransactionValue(token: decoration.tokenOut, value: resolvedAmountOut, sign: .plus),
                    foreignRecipient: decoration.to != evmKit.address
            )

        case let decoration as OneInchUnoswapMethodDecoration:
            var resolvedAmountIn = decoration.amountIn
            var resolvedAmountOut = decoration.amountOut ?? decoration.amountOutMin

            if fullTransaction.failed {
                resolvedAmountIn = 0
                resolvedAmountOut = 0
            }

            let valueIn = convertToTransactionValue(token: decoration.tokenIn, value: resolvedAmountIn, sign: .minus)
            var valueOut: TransactionValue? = nil

            if let tokenOut = decoration.tokenOut {
                valueOut = convertToTransactionValue(token: tokenOut, value: resolvedAmountOut, sign: .plus)
            }

            return SwapTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    valueIn: valueIn,
                    valueOut: valueOut,
                    foreignRecipient: false
            )

        case let decoration as OneInchSwapMethodDecoration:
            var tokenOut = decoration.tokenOut

            var resolvedAmountIn = decoration.amountIn
            var resolvedAmountOut = decoration.amountOut ?? decoration.amountOutMin

            if fullTransaction.failed {
                resolvedAmountIn = 0
                resolvedAmountOut = 0
            } else if fullTransaction.receiptWithLogs != nil, decoration.amountOut == nil {
                // Here we handle the case when transaction is completed, but reverted in smart contract.
                // In that case, it transfers sent tokens/ETH back. So we should make a SwapTransactionRecord
                // where token/ETH sent and token/ETH received are the same

                for event in fullTransaction.eventDecorations {
                    if let decoration = event as? TransferEventDecoration, decoration.to == evmKit.address, decoration.value > 0 {
                        tokenOut = .eip20Coin(address: decoration.contractAddress)
                        resolvedAmountOut = decoration.value
                    }
                }

                var internalETHs: BigUInt = 0
                for tx in fullTransaction.internalTransactions {
                    if tx.to == evmKit.address {
                        internalETHs += tx.value
                    }
                }

                if internalETHs > 0 {
                    tokenOut = .evmCoin
                    resolvedAmountOut = internalETHs
                }
            }

            return SwapTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    valueIn: convertToTransactionValue(token: decoration.tokenIn, value: resolvedAmountIn, sign: .minus),
                    valueOut: convertToTransactionValue(token: tokenOut, value: resolvedAmountOut, sign: .plus),
                    foreignRecipient: decoration.recipient != evmKit.address
            )

        case is OneInchMethodDecoration:
            return UnknownSwapTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    value: convertAmount(amount: fullTransaction.transaction.value, decimals: baseCoin.decimals, sign: .minus),
                    incomingInternalETHs: internalTransactions(from: fullTransaction),
                    incomingEip20Events: incomingEip20Events(from: fullTransaction),
                    outgoingEip20Events: outgoingEip20Events(from: fullTransaction)
            )

        case let decoration as RecognizedMethodDecoration:
            return ContractCallTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: decoration.method,
                    value: convertAmount(amount: fullTransaction.transaction.value, decimals: baseCoin.decimals, sign: .minus),
                    incomingInternalETHs: internalTransactions(from: fullTransaction),
                    incomingEip20Events: incomingEip20Events(from: fullTransaction),
                    outgoingEip20Events: outgoingEip20Events(from: fullTransaction)
            )

        case is UnknownMethodDecoration:
            return ContractCallTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: nil,
                    value: convertAmount(amount: fullTransaction.transaction.value, decimals: baseCoin.decimals, sign: .minus),
                    incomingInternalETHs: internalTransactions(from: fullTransaction),
                    incomingEip20Events: incomingEip20Events(from: fullTransaction),
                    outgoingEip20Events: outgoingEip20Events(from: fullTransaction)
            )

        default:
            return EvmTransactionRecord(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin)
        }
    }

    private func convertForeignCall(methodDecoration: ContractMethodDecoration, fullTransaction: FullTransaction, to: EthereumKit.Address) -> EvmTransactionRecord {
        switch methodDecoration {
        case let decoration as TransferMethodDecoration:
            if decoration.to == evmKit.address {
                return EvmIncomingTransactionRecord(
                        source: source,
                        fullTransaction: fullTransaction,
                        baseCoin: baseCoin,
                        from: fullTransaction.transaction.from.eip55,
                        value: eip20Value(tokenAddress: to, value: decoration.value, sign: .plus),
                        foreignTransaction: true
                )
            }

        case let decoration as RecognizedMethodDecoration:
            return ContractCallTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: decoration.method,
                    value: convertAmount(amount: fullTransaction.transaction.value, decimals: baseCoin.decimals, sign: .minus),
                    incomingInternalETHs: internalTransactions(from: fullTransaction),
                    incomingEip20Events: incomingEip20Events(from: fullTransaction),
                    outgoingEip20Events: outgoingEip20Events(from: fullTransaction),
                    foreignTransaction: true
            )

        case is UnknownMethodDecoration, is OneInchMethodDecoration:
            return ContractCallTransactionRecord(
                    source: source,
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: nil,
                    value: convertAmount(amount: fullTransaction.transaction.value, decimals: baseCoin.decimals, sign: .minus),
                    incomingInternalETHs: internalTransactions(from: fullTransaction),
                    incomingEip20Events: incomingEip20Events(from: fullTransaction),
                    outgoingEip20Events: outgoingEip20Events(from: fullTransaction),
                    foreignTransaction: true
            )

        default: ()
        }

        return EvmTransactionRecord(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

}

extension EvmTransactionConverter {

    func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> EvmTransactionRecord {
        let transaction = fullTransaction.transaction

        guard let to = transaction.to else {
            return ContractCreationTransactionRecord(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin)
        }

        let record: EvmTransactionRecord

        if let methodDecoration = fullTransaction.mainDecoration {
            if fullTransaction.transaction.from == evmKit.address {
                record = convertMyCall(methodDecoration: methodDecoration, fullTransaction: fullTransaction, to: to)
            } else {
                record = convertForeignCall(methodDecoration: methodDecoration, fullTransaction: fullTransaction, to: to)
            }
        } else {
            if transaction.from == evmKit.address {
                let amount = convertAmount(amount: transaction.value, decimals: baseCoin.decimals, sign: .minus)

                record = EvmOutgoingTransactionRecord(
                        source: source,
                        fullTransaction: fullTransaction,
                        baseCoin: baseCoin,
                        to: to.eip55,
                        value: .coinValue(platformCoin: baseCoin, value: amount),
                        sentToSelf: to == transaction.from
                )
            } else if to == evmKit.address {
                let amount = convertAmount(amount: transaction.value, decimals: baseCoin.decimals, sign: .plus)

                record = EvmIncomingTransactionRecord(
                        source: source,
                        fullTransaction: fullTransaction,
                        baseCoin: baseCoin,
                        from: transaction.from.eip55,
                        value: .coinValue(platformCoin: baseCoin, value: amount)
                )
            } else {
                record = EvmTransactionRecord(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin)
            }
        }

        return record
    }

}
