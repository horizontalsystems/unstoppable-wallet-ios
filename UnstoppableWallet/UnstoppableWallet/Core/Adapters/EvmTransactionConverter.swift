import Foundation
import EthereumKit
import Erc20Kit
import UniswapKit
import OneInchKit
import CoinKit
import BigInt

class EvmTransactionConverter {
    private let coinManager: ICoinManager
    private let evmKit: EthereumKit.Kit
    private let baseCoin: Coin

    init(coinManager: ICoinManager, evmKit: EthereumKit.Kit) {
        self.coinManager = coinManager
        self.evmKit = evmKit

        switch evmKit.networkType {
        case .bscMainNet: baseCoin = coinManager.coinOrStub(type: .binanceSmartChain)
        default: baseCoin = coinManager.coinOrStub(type: .ethereum)
        }
    }

    private func convertAmount(amount: BigUInt, decimal: Int, sign: FloatingPointSign) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: sign, exponent: -decimal, significand: significand)
    }

    private func eip20Coin(tokenAddress: EthereumKit.Address) -> Coin {
        let coinType: CoinType

        switch evmKit.networkType {
        case .bscMainNet: coinType = .bep20(address: tokenAddress.hex)
        default: coinType = .erc20(address: tokenAddress.hex)
        }

        return coinManager.coinOrStub(type: coinType)
    }

    private func convertToCoin(token: SwapMethodDecoration.Token) -> Coin {
        switch token {
        case .evmCoin:
            return baseCoin

        case .eip20Coin(let tokenAddress):
            switch evmKit.networkType {
            case .bscMainNet: return coinManager.coinOrStub(type: .bep20(address: tokenAddress.hex))
            default: return coinManager.coinOrStub(type: .erc20(address: tokenAddress.hex))
            }
        }
    }

    private func convertToCoin(token: OneInchMethodDecoration.Token) -> Coin {
        switch token {
        case .evmCoin:
            return baseCoin

        case .eip20Coin(let tokenAddress):
            switch evmKit.networkType {
            case .bscMainNet: return coinManager.coinOrStub(type: .bep20(address: tokenAddress.hex))
            default: return coinManager.coinOrStub(type: .erc20(address: tokenAddress.hex))
            }
        }
    }

    private func internalTransactions(from fullTransaction: FullTransaction) -> [ContractCallTransactionRecord.IncomingInternalETH] {
        fullTransaction.internalTransactions.compactMap { internalTransaction in
            guard internalTransaction.to == evmKit.address else {
                return nil
            }

            let amount = convertAmount(amount: internalTransaction.value, decimal: baseCoin.decimal, sign: .plus)
            return (from: internalTransaction.from.eip55, value: CoinValue(coin: baseCoin, value: amount))
        }
    }

    private func incomingEip20Events(from fullTransaction: FullTransaction) -> [ContractCallTransactionRecord.IncomingEip20Event] {
        fullTransaction.eventDecorations.compactMap { event in
            guard let decoration = event as? TransferEventDecoration, decoration.to == evmKit.address else {
                return nil
            }

            let token = eip20Coin(tokenAddress: decoration.contractAddress)
            let amount = convertAmount(amount: decoration.value, decimal: token.decimal, sign: .plus)

            return (from: decoration.from.eip55, value: CoinValue(coin: token, value: amount))
        }
    }

    private func outgoingEip20Events(from fullTransaction: FullTransaction) -> [ContractCallTransactionRecord.OutgoingEip20Event] {
        fullTransaction.eventDecorations.compactMap { event in
            guard let decoration = event as? TransferEventDecoration, decoration.from == evmKit.address else {
                return nil
            }

            let token = eip20Coin(tokenAddress: decoration.contractAddress)
            let amount = convertAmount(amount: decoration.value, decimal: token.decimal, sign: .minus)

            return (to: decoration.to.eip55, value: CoinValue(coin: token, value: amount))
        }
    }

    private func convertMyCall(methodDecoration: ContractMethodDecoration, fullTransaction: FullTransaction, to: EthereumKit.Address) -> EvmTransactionRecord {
        switch methodDecoration {
        case let decoration as TransferMethodDecoration:
            let token = eip20Coin(tokenAddress: to)

            return EvmOutgoingTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    amount: convertAmount(amount: decoration.value, decimal: token.decimal, sign: .minus),
                    to: decoration.to.eip55,
                    token: token,
                    sentToSelf: decoration.to == fullTransaction.transaction.from
            )

        case let decoration as ApproveMethodDecoration:
            let token = eip20Coin(tokenAddress: to)

            return ApproveTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    amount: convertAmount(amount: decoration.value, decimal: token.decimal, sign: .plus),
                    spender: decoration.spender.eip55,
                    token: token
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

            let tokenIn = convertToCoin(token: decoration.tokenIn)
            let tokenOut = convertToCoin(token: decoration.tokenOut)

            return SwapTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: convertAmount(amount: resolvedAmountIn, decimal: tokenIn.decimal, sign: .minus),
                    amountOut: convertAmount(amount: resolvedAmountOut, decimal: tokenOut.decimal, sign: .plus),
                    foreignRecipient: decoration.to != evmKit.address
            )

        case let decoration as OneInchUnoswapMethodDecoration:
            let tokenIn = convertToCoin(token: decoration.tokenIn)
            let tokenOut = decoration.tokenOut.flatMap { convertToCoin(token: $0) }

            var resolvedAmountIn = convertAmount(amount: decoration.amountIn, decimal: tokenIn.decimal, sign: .minus)
            var resolvedAmountOut = tokenOut.flatMap { convertAmount(amount: decoration.amountOut ?? decoration.amountOutMin, decimal: $0.decimal, sign: .plus) }

            if fullTransaction.failed {
                resolvedAmountIn = 0
                resolvedAmountOut = 0
            }

            return SwapTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: resolvedAmountIn,
                    amountOut: resolvedAmountOut,
                    foreignRecipient: false
            )

        case let decoration as OneInchSwapMethodDecoration:
            let tokenIn = convertToCoin(token: decoration.tokenIn)
            var tokenOut = convertToCoin(token: decoration.tokenOut)

            var resolvedAmountIn = convertAmount(amount: decoration.amountIn, decimal: tokenIn.decimal, sign: .minus)
            var resolvedAmountOut = convertAmount(amount: decoration.amountOut ?? decoration.amountOutMin, decimal: tokenOut.decimal, sign: .plus)

            if fullTransaction.failed {
                resolvedAmountIn = 0
                resolvedAmountOut = 0
            } else if fullTransaction.receiptWithLogs != nil, decoration.amountOut == nil {
                for event in incomingEip20Events(from: fullTransaction) {
                    if event.value.value > 0 {
                        tokenOut = event.value.coin
                        resolvedAmountOut = event.value.value
                    }
                }

                var internalETHs: Decimal = 0
                for tx in internalTransactions(from: fullTransaction) {
                    internalETHs += tx.value.value
                }

                if internalETHs > 0 {
                    tokenOut = baseCoin
                    resolvedAmountOut = internalETHs
                }
            }

            return SwapTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: resolvedAmountIn,
                    amountOut: resolvedAmountOut,
                    foreignRecipient: decoration.recipient != evmKit.address
            )

        case let decoration as RecognizedMethodDecoration:
            return ContractCallTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: decoration.method,
                    value: convertAmount(amount: fullTransaction.transaction.value, decimal: baseCoin.decimal, sign: .minus),
                    incomingInternalETHs: internalTransactions(from: fullTransaction),
                    incomingEip20Events: incomingEip20Events(from: fullTransaction),
                    outgoingEip20Events: outgoingEip20Events(from: fullTransaction)
            )

        case is UnknownMethodDecoration:
            return ContractCallTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: nil,
                    value: convertAmount(amount: fullTransaction.transaction.value, decimal: baseCoin.decimal, sign: .minus),
                    incomingInternalETHs: internalTransactions(from: fullTransaction),
                    incomingEip20Events: incomingEip20Events(from: fullTransaction),
                    outgoingEip20Events: outgoingEip20Events(from: fullTransaction)
            )

        default:
            return EvmTransactionRecord(fullTransaction: fullTransaction, baseCoin: baseCoin)
        }
    }

    private func convertForeignCall(methodDecoration: ContractMethodDecoration, fullTransaction: FullTransaction, to: EthereumKit.Address) -> EvmTransactionRecord {
        switch methodDecoration {
        case let decoration as TransferMethodDecoration:
            if decoration.to == evmKit.address {
                let token = eip20Coin(tokenAddress: to)

                return EvmIncomingTransactionRecord(
                        fullTransaction: fullTransaction,
                        baseCoin: baseCoin,
                        amount: convertAmount(amount: decoration.value, decimal: token.decimal, sign: .plus),
                        from: decoration.to.eip55,
                        token: token,
                        foreignTransaction: true
                )
            }

        case let decoration as RecognizedMethodDecoration:
            return ContractCallTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: decoration.method,
                    value: convertAmount(amount: fullTransaction.transaction.value, decimal: baseCoin.decimal, sign: .minus),
                    incomingInternalETHs: internalTransactions(from: fullTransaction),
                    incomingEip20Events: incomingEip20Events(from: fullTransaction),
                    outgoingEip20Events: outgoingEip20Events(from: fullTransaction),
                    foreignTransaction: true
            )

        case is UnknownMethodDecoration:
            return ContractCallTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: nil,
                    value: convertAmount(amount: fullTransaction.transaction.value, decimal: baseCoin.decimal, sign: .minus),
                    incomingInternalETHs: internalTransactions(from: fullTransaction),
                    incomingEip20Events: incomingEip20Events(from: fullTransaction),
                    outgoingEip20Events: outgoingEip20Events(from: fullTransaction),
                    foreignTransaction: true
            )

        default: ()
        }

        return EvmTransactionRecord(fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

}

extension EvmTransactionConverter {

    func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> EvmTransactionRecord {
        let transaction = fullTransaction.transaction

        guard let to = transaction.to else {
            return ContractCreationTransactionRecord(fullTransaction: fullTransaction, baseCoin: baseCoin)
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
                record = EvmOutgoingTransactionRecord(
                        fullTransaction: fullTransaction,
                        baseCoin: baseCoin,
                        amount: convertAmount(amount: transaction.value, decimal: baseCoin.decimal, sign: .minus),
                        to: to.eip55,
                        token: baseCoin,
                        sentToSelf: to == transaction.from
                )
            } else if to == evmKit.address {
                record = EvmIncomingTransactionRecord(
                        fullTransaction: fullTransaction,
                        baseCoin: baseCoin,
                        amount: convertAmount(amount: transaction.value, decimal: baseCoin.decimal, sign: .plus),
                        from: transaction.from.eip55,
                        token: baseCoin
                )
            } else {
                record = EvmTransactionRecord(fullTransaction: fullTransaction, baseCoin: baseCoin)
            }
        }

        return record
    }

}
