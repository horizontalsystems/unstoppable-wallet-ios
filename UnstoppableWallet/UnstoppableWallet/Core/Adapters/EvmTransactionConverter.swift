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

    private func eip20Value(tokenAddress: EthereumKit.Address, value: BigUInt, sign: FloatingPointSign, tokenInfo: TokenInfo?) -> TransactionValue {
        let coinType = evmKitWrapper.blockchain.evm20CoinType(address: tokenAddress.hex)

        if let platformCoin = try? coinManager.platformCoin(coinType: coinType) {
            let value = convertAmount(amount: value, decimals: platformCoin.decimals, sign: sign)
            return .coinValue(platformCoin: platformCoin, value: value)
        } else if let tokenInfo = tokenInfo {
            let value = convertAmount(amount: value, decimals: tokenInfo.tokenDecimal, sign: sign)
            return .tokenValue(tokenName: tokenInfo.tokenName, tokenCode: tokenInfo.tokenSymbol, tokenDecimals: tokenInfo.tokenDecimal, value: value)
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
        case .eip20Coin(let tokenAddress, let tokenInfo): return eip20Value(tokenAddress: tokenAddress, value: value, sign: sign, tokenInfo: tokenInfo)
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
        case .eip20Coin(let tokenAddress, let tokenInfo): return eip20Value(tokenAddress: tokenAddress, value: value, sign: sign, tokenInfo: tokenInfo)
        }
    }

    private func transferEvents(incomingTransfers: [TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        incomingTransfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.from.eip55,
                    value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .plus, tokenInfo: transfer.tokenInfo)
            )
        }
    }

    private func transferEvents(outgoingTransfers: [TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        outgoingTransfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.to.eip55,
                    value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .minus, tokenInfo: transfer.tokenInfo)
            )
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

    private func transferEvents(contractAddress: EthereumKit.Address, value: BigUInt) -> [ContractCallTransactionRecord.TransferEvent] {
        guard value != 0 else {
            return []
        }

        let event = ContractCallTransactionRecord.TransferEvent(
                address: contractAddress.eip55,
                value: baseCoinValue(value: value, sign: .minus)
        )

        return [event]
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
                    value: eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .minus, tokenInfo: decoration.tokenInfo),
                    sentToSelf: decoration.sentToSelf
            )

        case let decoration as ApproveEip20Decoration:
            return ApproveTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    spender: decoration.spender.eip55,
                    value: eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .plus, tokenInfo: nil)
            )

        case let decoration as SwapDecoration:
            return SwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    exchangeAddress: decoration.contractAddress.eip55,
                    amountIn: convertToAmount(token: decoration.tokenIn, amount: decoration.amountIn, sign: .minus),
                    amountOut: convertToAmount(token: decoration.tokenOut, amount: decoration.amountOut, sign: .plus),
                    recipient: decoration.recipient?.eip55
            )

        case let decoration as OneInchSwapDecoration:
            return SwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    exchangeAddress: decoration.contractAddress.eip55,
                    amountIn: .exact(value: convertToTransactionValue(token: decoration.tokenIn, value: decoration.amountIn, sign: .minus)),
                    amountOut: convertToAmount(token: decoration.tokenOut, amount: decoration.amountOut, sign: .plus),
                    recipient: decoration.recipient?.eip55
            )

        case let decoration as OneInchUnoswapDecoration:
            return SwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    exchangeAddress: decoration.contractAddress.eip55,
                    amountIn: .exact(value: convertToTransactionValue(token: decoration.tokenIn, value: decoration.amountIn, sign: .minus)),
                    amountOut: decoration.tokenOut.map { convertToAmount(token: $0, amount: decoration.amountOut, sign: .plus) },
                    recipient: nil
            )

        case let decoration as OneInchUnknownSwapDecoration:
            return UnknownSwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseCoin: baseCoin,
                    exchangeAddress: decoration.contractAddress.eip55,
                    valueIn: decoration.tokenAmountIn.map { convertToTransactionValue(token: $0.token, value: $0.value, sign: .minus) },
                    valueOut: decoration.tokenAmountOut.map { convertToTransactionValue(token: $0.token, value: $0.value, sign: .plus) }
            )

        case let decoration as UnknownTransactionDecoration:
            let address = evmKit.address

            let internalTransactions = decoration.internalTransactions.filter { $0.to == address }

            let transferEventInstances = decoration.eventInstances.compactMap { $0 as? TransferEventInstance }
            let incomingTransfers = transferEventInstances.filter { $0.to == address && $0.from != address }
            let outgoingTransfers = transferEventInstances.filter { $0.from == address }

            if transaction.from == address, let contractAddress = transaction.to, let value = transaction.value {
                return ContractCallTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseCoin: baseCoin,
                        contractAddress: contractAddress.eip55,
                        method: nil,
                        incomingEvents: transferEvents(internalTransactions: internalTransactions) + transferEvents(incomingTransfers: incomingTransfers),
                        outgoingEvents: transferEvents(contractAddress: contractAddress, value: value) + transferEvents(outgoingTransfers: outgoingTransfers)
                )
            } else if transaction.from != address {
                return ExternalContractCallTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseCoin: baseCoin,
                        incomingEvents: transferEvents(internalTransactions: internalTransactions) + transferEvents(incomingTransfers: incomingTransfers),
                        outgoingEvents: transferEvents(outgoingTransfers: outgoingTransfers)
                )
            }

        default: ()
        }

        return EvmTransactionRecord(
                source: source,
                transaction: transaction,
                baseCoin: baseCoin,
                ownTransaction: transaction.from == evmKit.address
        )
    }

}
