import Foundation
import EvmKit
import Eip20Kit
import NftKit
import UniswapKit
import OneInchKit
import MarketKit
import BigInt

class EvmTransactionConverter {
    private let coinManager: CoinManager
    private let evmKitWrapper: EvmKitWrapper
    private let evmLabelManager: EvmLabelManager
    private let source: TransactionSource
    private let baseToken: MarketKit.Token

    init(source: TransactionSource, baseToken: MarketKit.Token, coinManager: CoinManager, evmKitWrapper: EvmKitWrapper, evmLabelManager: EvmLabelManager) {
        self.coinManager = coinManager
        self.evmKitWrapper = evmKitWrapper
        self.evmLabelManager = evmLabelManager
        self.source = source
        self.baseToken = baseToken
    }

    private var evmKit: EvmKit.Kit {
        evmKitWrapper.evmKit
    }

    private func convertAmount(amount: BigUInt, decimals: Int, sign: FloatingPointSign) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: sign, exponent: -decimals, significand: significand)
    }

    private func baseCoinValue(value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        let amount = convertAmount(amount: value, decimals: baseToken.decimals, sign: sign)
        return .coinValue(token: baseToken, value: amount)
    }

    private func eip20Value(tokenAddress: EvmKit.Address, value: BigUInt, sign: FloatingPointSign, tokenInfo: Eip20Kit.TokenInfo?) -> TransactionValue {
        let query = TokenQuery(blockchainType: evmKitWrapper.blockchainType, tokenType: .eip20(address: tokenAddress.hex))

        if let token = try? coinManager.token(query: query) {
            let value = convertAmount(amount: value, decimals: token.decimals, sign: sign)
            return .coinValue(token: token, value: value)
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

    private func transferEvents(incomingEip20Transfers: [TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        incomingEip20Transfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.from.eip55,
                    value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .plus, tokenInfo: transfer.tokenInfo)
            )
        }
    }

    private func transferEvents(outgoingEip20Transfers: [TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        outgoingEip20Transfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.to.eip55,
                    value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .minus, tokenInfo: transfer.tokenInfo)
            )
        }
    }

    private func transferEvents(incomingEip721Transfers: [Eip721TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        incomingEip721Transfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.from.eip55,
                    value: .nftValue(
                            nftUid: .evm(blockchainType: source.blockchainType, contractAddress: transfer.contractAddress.hex, tokenId: transfer.tokenId.description),
                            value: 1,
                            tokenName: transfer.tokenInfo?.tokenName,
                            tokenSymbol: transfer.tokenInfo?.tokenSymbol
                    )
            )
        }
    }

    private func transferEvents(outgoingEip721Transfers: [Eip721TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        outgoingEip721Transfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.to.eip55,
                    value: .nftValue(
                            nftUid: .evm(blockchainType: source.blockchainType, contractAddress: transfer.contractAddress.hex, tokenId: transfer.tokenId.description),
                            value: -1,
                            tokenName: transfer.tokenInfo?.tokenName,
                            tokenSymbol: transfer.tokenInfo?.tokenSymbol
                    )
            )
        }
    }

    private func transferEvents(incomingEip1155Transfers: [Eip1155TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        incomingEip1155Transfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.from.eip55,
                    value: .nftValue(
                            nftUid: .evm(blockchainType: source.blockchainType, contractAddress: transfer.contractAddress.hex, tokenId: transfer.tokenId.description),
                            value: convertAmount(amount: transfer.value, decimals: 0, sign: .plus),
                            tokenName: transfer.tokenInfo?.tokenName,
                            tokenSymbol: transfer.tokenInfo?.tokenSymbol
                    )
            )
        }
    }

    private func transferEvents(outgoingEip1155Transfers: [Eip1155TransferEventInstance]) -> [ContractCallTransactionRecord.TransferEvent] {
        outgoingEip1155Transfers.map { transfer in
            ContractCallTransactionRecord.TransferEvent(
                    address: transfer.to.eip55,
                    value: .nftValue(
                            nftUid: .evm(blockchainType: source.blockchainType, contractAddress: transfer.contractAddress.hex, tokenId: transfer.tokenId.description),
                            value: convertAmount(amount: transfer.value, decimals: 0, sign: .minus),
                            tokenName: transfer.tokenInfo?.tokenName,
                            tokenSymbol: transfer.tokenInfo?.tokenSymbol
                    )
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

    private func transferEvents(contractAddress: EvmKit.Address, value: BigUInt) -> [ContractCallTransactionRecord.TransferEvent] {
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
                    baseToken: baseToken
            )

        case let decoration as IncomingDecoration:
            return EvmIncomingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    from: decoration.from.eip55,
                    value: baseCoinValue(value: decoration.value, sign: .plus)
            )

        case let decoration as OutgoingDecoration:
            return EvmOutgoingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    to: decoration.to.eip55,
                    value: baseCoinValue(value: decoration.value, sign: .minus),
                    sentToSelf: decoration.sentToSelf
            )

        case let decoration as OutgoingEip20Decoration:
            return EvmOutgoingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    to: decoration.to.eip55,
                    value: eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .minus, tokenInfo: decoration.tokenInfo),
                    sentToSelf: decoration.sentToSelf
            )

        case let decoration as ApproveEip20Decoration:
            return ApproveTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    spender: decoration.spender.eip55,
                    value: eip20Value(tokenAddress: decoration.contractAddress, value: decoration.value, sign: .plus, tokenInfo: nil)
            )

        case let decoration as SwapDecoration:
            return SwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    exchangeAddress: decoration.contractAddress.eip55,
                    amountIn: convertToAmount(token: decoration.tokenIn, amount: decoration.amountIn, sign: .minus),
                    amountOut: convertToAmount(token: decoration.tokenOut, amount: decoration.amountOut, sign: .plus),
                    recipient: decoration.recipient?.eip55
            )

        case let decoration as OneInchSwapDecoration:
            return SwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    exchangeAddress: decoration.contractAddress.eip55,
                    amountIn: .exact(value: convertToTransactionValue(token: decoration.tokenIn, value: decoration.amountIn, sign: .minus)),
                    amountOut: convertToAmount(token: decoration.tokenOut, amount: decoration.amountOut, sign: .plus),
                    recipient: decoration.recipient?.eip55
            )

        case let decoration as OneInchUnoswapDecoration:
            return SwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    exchangeAddress: decoration.contractAddress.eip55,
                    amountIn: .exact(value: convertToTransactionValue(token: decoration.tokenIn, value: decoration.amountIn, sign: .minus)),
                    amountOut: decoration.tokenOut.map { convertToAmount(token: $0, amount: decoration.amountOut, sign: .plus) },
                    recipient: nil
            )

        case let decoration as OneInchUnknownSwapDecoration:
            return UnknownSwapTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    exchangeAddress: decoration.contractAddress.eip55,
                    valueIn: decoration.tokenAmountIn.map { convertToTransactionValue(token: $0.token, value: $0.value, sign: .minus) },
                    valueOut: decoration.tokenAmountOut.map { convertToTransactionValue(token: $0.token, value: $0.value, sign: .plus) }
            )

        case let decoration as Eip721SafeTransferFromDecoration:
            return EvmOutgoingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    to: decoration.to.eip55,
                    value: .nftValue(
                            nftUid: .evm(blockchainType: source.blockchainType, contractAddress: decoration.contractAddress.hex, tokenId: decoration.tokenId.description),
                            value: convertAmount(amount: 1, decimals: 0, sign: .minus),
                            tokenName: decoration.tokenInfo?.tokenName,
                            tokenSymbol: decoration.tokenInfo?.tokenSymbol
                    ),
                    sentToSelf: decoration.sentToSelf
            )

        case let decoration as Eip1155SafeTransferFromDecoration:
            return EvmOutgoingTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    to: decoration.to.eip55,
                    value: .nftValue(
                            nftUid: .evm(blockchainType: source.blockchainType, contractAddress: decoration.contractAddress.hex, tokenId: decoration.tokenId.description),
                            value: convertAmount(amount: decoration.value, decimals: 0, sign: .minus),
                            tokenName: decoration.tokenInfo?.tokenName,
                            tokenSymbol: decoration.tokenInfo?.tokenSymbol
                    ),
                    sentToSelf: decoration.sentToSelf
            )

        case let decoration as UnknownTransactionDecoration:
            let address = evmKit.address

            let internalTransactions = decoration.internalTransactions.filter { $0.to == address }

            let eip20Transfers = decoration.eventInstances.compactMap { $0 as? TransferEventInstance }
            let incomingEip20Transfers = eip20Transfers.filter { $0.to == address && $0.from != address }
            let outgoingEip20Transfers = eip20Transfers.filter { $0.from == address }

            let eip721Transfers = decoration.eventInstances.compactMap { $0 as? Eip721TransferEventInstance }
            let incomingEip721Transfers = eip721Transfers.filter { $0.to == address && $0.from != address }
            let outgoingEip721Transfers = eip721Transfers.filter { $0.from == address }

            let eip1155Transfers = decoration.eventInstances.compactMap { $0 as? Eip1155TransferEventInstance }
            let incomingEip1155Transfers = eip1155Transfers.filter { $0.to == address && $0.from != address }
            let outgoingEip1155Transfers = eip1155Transfers.filter { $0.from == address }

            if transaction.from == address, let contractAddress = transaction.to, let value = transaction.value {
                return ContractCallTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseToken: baseToken,
                        contractAddress: contractAddress.eip55,
                        method: transaction.input.flatMap { evmLabelManager.methodLabel(input: $0) },
                        incomingEvents: transferEvents(internalTransactions: internalTransactions) + transferEvents(incomingEip20Transfers: incomingEip20Transfers) +
                                transferEvents(incomingEip721Transfers: incomingEip721Transfers) + transferEvents(incomingEip1155Transfers: incomingEip1155Transfers),
                        outgoingEvents: transferEvents(contractAddress: contractAddress, value: value) + transferEvents(outgoingEip20Transfers: outgoingEip20Transfers) +
                                transferEvents(outgoingEip721Transfers: outgoingEip721Transfers) + transferEvents(outgoingEip1155Transfers: outgoingEip1155Transfers)
                )
            } else if transaction.from != address && transaction.to != address {
                return ExternalContractCallTransactionRecord(
                        source: source,
                        transaction: transaction,
                        baseToken: baseToken,
                        incomingEvents: transferEvents(internalTransactions: internalTransactions) + transferEvents(incomingEip20Transfers: incomingEip20Transfers) +
                                transferEvents(incomingEip721Transfers: incomingEip721Transfers) + transferEvents(incomingEip1155Transfers: incomingEip1155Transfers),
                        outgoingEvents: transferEvents(outgoingEip20Transfers: outgoingEip20Transfers) +
                                transferEvents(outgoingEip721Transfers: outgoingEip721Transfers) + transferEvents(outgoingEip1155Transfers: outgoingEip1155Transfers)
                )
            }

        default: ()
        }

        return EvmTransactionRecord(
                source: source,
                transaction: transaction,
                baseToken: baseToken,
                ownTransaction: transaction.from == evmKit.address
        )
    }

}
