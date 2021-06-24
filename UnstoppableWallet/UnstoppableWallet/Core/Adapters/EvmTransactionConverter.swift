import Foundation
import EthereumKit
import Erc20Kit
import UniswapKit
import CoinKit
import BigInt

class EvmTransactionConverter {
    private let coinManager: ICoinManager
    private let evmKit: EthereumKit.Kit

    init(coinManager: ICoinManager, evmKit: EthereumKit.Kit) {
        self.coinManager = coinManager
        self.evmKit = evmKit
    }

    private func convertAmount(amount: BigUInt, decimal: Int, sign: FloatingPointSign) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: sign, exponent: -decimal, significand: significand)
    }

    private func coin(from coinType: CoinType) -> Coin {
        coinManager.coin(type: coinType) ?? Coin(title: "", code: "", decimal: 18, type: coinType)
    }

    private func eip20Coin(tokenAddress: EthereumKit.Address) -> Coin {
        let coinType: CoinType

        switch evmKit.networkType {
        case .bscMainNet: coinType = .bep20(address: tokenAddress.hex)
        default: coinType = .erc20(address: tokenAddress.hex)
        }

        return coin(from: coinType)
    }

    private func convertToCoin(token: SwapMethodDecoration.Token) -> Coin {
        switch token {
        case .evmCoin:
            switch evmKit.networkType {
            case .bscMainNet: return coin(from: .binanceSmartChain)
            default: return coin(from: .ethereum)
            }

        case .eip20Coin(let tokenAddress):
            switch evmKit.networkType {
            case .bscMainNet: return coin(from: .bep20(address: tokenAddress.hex))
            default: return coin(from: .erc20(address: tokenAddress.hex))
            }
        }
    }

    private func convertMyCall(methodDecoration: ContractMethodDecoration, fullTransaction: FullTransaction, to: EthereumKit.Address) -> EvmTransactionRecord {
        switch methodDecoration {
        case let decoration as TransferMethodDecoration:
            let token = eip20Coin(tokenAddress: to)

            return EvmOutgoingTransactionRecord(
                    fullTransaction: fullTransaction,
                    amount: convertAmount(amount: decoration.value, decimal: token.decimal, sign: .minus),
                    to: decoration.to.eip55,
                    token: token,
                    sentToSelf: decoration.to == fullTransaction.transaction.from
            )

        case let decoration as ApproveMethodDecoration:
            let token = eip20Coin(tokenAddress: to)

            return ApproveTransactionRecord(
                    fullTransaction: fullTransaction,
                    amount: convertAmount(amount: decoration.value, decimal: token.decimal, sign: .plus),
                    spender: decoration.spender.eip55,
                    token: token
            )

        case let decoration as SwapMethodDecoration:
            let resolvedAmountIn: BigUInt
            let resolvedAmountOut: BigUInt

            switch decoration.trade {
            case .exactIn(let amountIn, let amountOutMin, let amountOut):
                resolvedAmountIn = amountIn
                resolvedAmountOut = amountOut ?? amountOutMin

            case .exactOut(let amountOut, let amountInMax, let amountIn):
                resolvedAmountIn = amountIn ?? amountInMax
                resolvedAmountOut = amountOut
            }

            let tokenIn = convertToCoin(token: decoration.tokenIn)
            let tokenOut = convertToCoin(token: decoration.tokenOut)

            return SwapTransactionRecord(
                    fullTransaction: fullTransaction,
                    exchangeAddress: to.eip55,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: convertAmount(amount: resolvedAmountIn, decimal: tokenIn.decimal, sign: .minus),
                    amountOut: convertAmount(amount: resolvedAmountOut, decimal: tokenOut.decimal, sign: .plus),
                    foreignRecipient: decoration.to == evmKit.address
            )

        case let decoration as RecognizedMethodDecoration:
            return ContractCallTransactionRecord(fullTransaction: fullTransaction, contractAddress: to.eip55, method: decoration.method)

        case let decoration as UnknownMethodDecoration:
            return ContractCallTransactionRecord(fullTransaction: fullTransaction, contractAddress: to.eip55, method: nil)

        default:
            return EvmTransactionRecord(fullTransaction: fullTransaction)
        }
    }

    private func convertForeignCall(methodDecoration: ContractMethodDecoration, fullTransaction: FullTransaction, to: EthereumKit.Address) -> EvmTransactionRecord {
        switch methodDecoration {
        case let decoration as TransferMethodDecoration:
            if decoration.to == evmKit.address {
                let token = eip20Coin(tokenAddress: to)

                return EvmIncomingTransactionRecord(
                        fullTransaction: fullTransaction,
                        amount: convertAmount(amount: decoration.value, decimal: token.decimal, sign: .plus),
                        from: decoration.to.eip55,
                        token: token
                )
            }

        case let decoration as SwapMethodDecoration:
            if decoration.to == evmKit.address {
                let resolvedAmountIn: BigUInt
                let resolvedAmountOut: BigUInt

                switch decoration.trade {
                case .exactIn(let amountIn, let amountOutMin, let amountOut):
                    resolvedAmountIn = amountIn
                    resolvedAmountOut = amountOut ?? amountOutMin

                case .exactOut(let amountOut, let amountInMax, let amountIn):
                    resolvedAmountIn = amountIn ?? amountInMax
                    resolvedAmountOut = amountOut
                }

                let token = convertToCoin(token: decoration.tokenOut)

                return EvmIncomingTransactionRecord(
                        fullTransaction: fullTransaction,
                        amount: convertAmount(amount: resolvedAmountOut, decimal: token.decimal, sign: .plus),
                        from: decoration.to.eip55,
                        token: token
                )
            }

        case let decoration as RecognizedMethodDecoration:
            return ContractCallTransactionRecord(fullTransaction: fullTransaction, contractAddress: to.eip55, method: decoration.method)

        case is UnknownMethodDecoration:
            return ContractCallTransactionRecord(fullTransaction: fullTransaction, contractAddress: to.eip55, method: nil)

        default: ()
        }

        return EvmTransactionRecord(fullTransaction: fullTransaction)
    }

}

extension EvmTransactionConverter {

    func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> EvmTransactionRecord {
        let transaction = fullTransaction.transaction

        guard let to = transaction.to else {
            return ContractCreationTransactionRecord(fullTransaction: fullTransaction)
        }

        let record: EvmTransactionRecord
        let baseCoin: Coin

        switch evmKit.networkType {
        case .bscMainNet: baseCoin = coin(from: .binanceSmartChain)
        default: baseCoin = coin(from: .ethereum)
        }

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
                        amount: convertAmount(amount: transaction.value, decimal: baseCoin.decimal, sign: .minus),
                        to: to.eip55,
                        token: baseCoin,
                        sentToSelf: to == transaction.from
                )
            } else if to == evmKit.address {
                record = EvmIncomingTransactionRecord(
                        fullTransaction: fullTransaction,
                        amount: convertAmount(amount: transaction.value, decimal: baseCoin.decimal, sign: .plus),
                        from: transaction.from.eip55,
                        token: baseCoin
                )
            } else {
                record = EvmTransactionRecord(fullTransaction: fullTransaction)
            }
        }

        if record is ContractCallTransactionRecord {
            for internalTransaction in fullTransaction.internalTransactions {
                if internalTransaction.to == evmKit.address {
                    let amount = convertAmount(amount: internalTransaction.value, decimal: baseCoin.decimal, sign: .plus)
                    record.incomingInternalETHs.append((from: internalTransaction.from.eip55, amount: amount))
                }
            }

            for event in fullTransaction.eventDecorations {
                if let decoration = event as? TransferEventDecoration {
                    let token = eip20Coin(tokenAddress: decoration.contractAddress)

                    if decoration.from == evmKit.address {
                        let amount = convertAmount(amount: decoration.value, decimal: token.decimal, sign: .minus)

                        record.outgoingEip20Events.append((to: decoration.to.eip55, amount: amount))
                    } else if decoration.to == evmKit.address {
                        let amount = convertAmount(amount: decoration.value, decimal: token.decimal, sign: .plus)

                        record.incomingEip20Events.append((from: decoration.from.eip55, amount: amount))
                    }
                }
            }
        }

        return record
    }

}
