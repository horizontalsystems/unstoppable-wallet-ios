import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit
import NftKit
import OneInchKit
import UniswapKit

class EvmTransactionConverter {
    private let coinManager: CoinManager
    private let blockchainType: BlockchainType
    private let userAddress: EvmKit.Address
    private let evmLabelManager: EvmLabelManager
    private let source: TransactionSource
    private let baseToken: MarketKit.Token

    init(source: TransactionSource, baseToken: MarketKit.Token, coinManager: CoinManager, blockchainType: BlockchainType, userAddress: EvmKit.Address, evmLabelManager: EvmLabelManager) {
        self.coinManager = coinManager
        self.blockchainType = blockchainType
        self.userAddress = userAddress
        self.evmLabelManager = evmLabelManager
        self.source = source
        self.baseToken = baseToken
    }

    private func convertAmount(amount: BigUInt, decimals: Int, sign: FloatingPointSign) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: sign, exponent: -decimals, significand: significand)
    }

    private func baseAppValue(value: BigUInt, sign: FloatingPointSign) -> AppValue {
        let amount = convertAmount(amount: value, decimals: baseToken.decimals, sign: sign)
        return AppValue(token: baseToken, value: amount)
    }

    private func eip20Value(tokenAddress: EvmKit.Address, value: BigUInt, sign: FloatingPointSign, tokenInfo: Eip20Kit.TokenInfo?) -> AppValue {
        let query = TokenQuery(blockchainType: blockchainType, tokenType: .eip20(address: tokenAddress.hex))

        if let token = try? coinManager.token(query: query) {
            let value = convertAmount(amount: value, decimals: token.decimals, sign: sign)
            return AppValue(token: token, value: value)
        } else if let tokenInfo {
            let value = convertAmount(amount: value, decimals: tokenInfo.tokenDecimal, sign: sign)
            return AppValue(tokenName: tokenInfo.tokenName, tokenCode: tokenInfo.tokenSymbol, tokenDecimals: tokenInfo.tokenDecimal, value: value)
        }

        return AppValue(value: convertAmount(amount: value, decimals: 0, sign: sign))
    }

    private func convertToAmount(token: SwapDecoration.Token, amount: SwapDecoration.Amount, sign: FloatingPointSign) -> SwapTransactionRecord.Amount {
        switch amount {
        case let .exact(value): return .exact(value: convertToAppValue(token: token, value: value, sign: sign))
        case let .extremum(value): return .extremum(value: convertToAppValue(token: token, value: value, sign: sign))
        }
    }

    private func convertToAppValue(token: SwapDecoration.Token, value: BigUInt, sign: FloatingPointSign) -> AppValue {
        switch token {
        case .evmCoin: return baseAppValue(value: value, sign: sign)
        case let .eip20Coin(tokenAddress, tokenInfo): return eip20Value(tokenAddress: tokenAddress, value: value, sign: sign, tokenInfo: tokenInfo)
        }
    }

    private func convertToAmount(token: OneInchDecoration.Token, amount: OneInchDecoration.Amount, sign: FloatingPointSign) -> SwapTransactionRecord.Amount {
        switch amount {
        case let .exact(value): return .exact(value: convertToAppValue(token: token, value: value, sign: sign))
        case let .extremum(value): return .extremum(value: convertToAppValue(token: token, value: value, sign: sign))
        }
    }

    private func convertToAppValue(token: OneInchDecoration.Token, value: BigUInt, sign: FloatingPointSign) -> AppValue {
        switch token {
        case .evmCoin: return baseAppValue(value: value, sign: sign)
        case let .eip20Coin(tokenAddress, tokenInfo): return eip20Value(tokenAddress: tokenAddress, value: value, sign: sign, tokenInfo: tokenInfo)
        }
    }

    private func transferEvents(incomingEip20Transfers: [TransferEventInstance]) -> [TransferEvent] {
        incomingEip20Transfers.map { transfer in
            TransferEvent(
                address: transfer.from.eip55,
                value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .plus, tokenInfo: transfer.tokenInfo)
            )
        }
    }

    private func transferEvents(outgoingEip20Transfers: [TransferEventInstance]) -> [TransferEvent] {
        outgoingEip20Transfers.map { transfer in
            TransferEvent(
                address: transfer.to.eip55,
                value: eip20Value(tokenAddress: transfer.contractAddress, value: transfer.value, sign: .minus, tokenInfo: transfer.tokenInfo)
            )
        }
    }

    private func transferEvents(incomingEip721Transfers: [Eip721TransferEventInstance]) -> [TransferEvent] {
        incomingEip721Transfers.map { transfer in
            TransferEvent(
                address: transfer.from.eip55,
                value: AppValue(
                    nftUid: .evm(blockchainType: source.blockchainType, contractAddress: transfer.contractAddress.hex, tokenId: transfer.tokenId.description),
                    tokenName: transfer.tokenInfo?.tokenName,
                    tokenSymbol: transfer.tokenInfo?.tokenSymbol,
                    value: 1
                )
            )
        }
    }

    private func transferEvents(outgoingEip721Transfers: [Eip721TransferEventInstance]) -> [TransferEvent] {
        outgoingEip721Transfers.map { transfer in
            TransferEvent(
                address: transfer.to.eip55,
                value: AppValue(
                    nftUid: .evm(blockchainType: source.blockchainType, contractAddress: transfer.contractAddress.hex, tokenId: transfer.tokenId.description),
                    tokenName: transfer.tokenInfo?.tokenName,
                    tokenSymbol: transfer.tokenInfo?.tokenSymbol,
                    value: -1
                )
            )
        }
    }

    private func transferEvents(incomingEip1155Transfers: [Eip1155TransferEventInstance]) -> [TransferEvent] {
        incomingEip1155Transfers.map { transfer in
            TransferEvent(
                address: transfer.from.eip55,
                value: AppValue(
                    nftUid: .evm(blockchainType: source.blockchainType, contractAddress: transfer.contractAddress.hex, tokenId: transfer.tokenId.description),
                    tokenName: transfer.tokenInfo?.tokenName,
                    tokenSymbol: transfer.tokenInfo?.tokenSymbol,
                    value: convertAmount(amount: transfer.value, decimals: 0, sign: .plus)
                )
            )
        }
    }

    private func transferEvents(outgoingEip1155Transfers: [Eip1155TransferEventInstance]) -> [TransferEvent] {
        outgoingEip1155Transfers.map { transfer in
            TransferEvent(
                address: transfer.to.eip55,
                value: AppValue(
                    nftUid: .evm(blockchainType: source.blockchainType, contractAddress: transfer.contractAddress.hex, tokenId: transfer.tokenId.description),
                    tokenName: transfer.tokenInfo?.tokenName,
                    tokenSymbol: transfer.tokenInfo?.tokenSymbol,
                    value: convertAmount(amount: transfer.value, decimals: 0, sign: .minus)
                )
            )
        }
    }

    private func transferEvents(internalTransactions: [InternalTransaction]) -> [TransferEvent] {
        internalTransactions.map { internalTransaction in
            TransferEvent(
                address: internalTransaction.from.eip55,
                value: baseAppValue(value: internalTransaction.value, sign: .plus)
            )
        }
    }

    private func transferEvents(contractAddress: EvmKit.Address, value: BigUInt) -> [TransferEvent] {
        guard value != 0 else {
            return []
        }

        let event = TransferEvent(
            address: contractAddress.eip55,
            value: baseAppValue(value: value, sign: .minus)
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
            let appValue = baseAppValue(value: decoration.value, sign: .plus)
            let spam = SpamManager.isSpam(events: [.init(address: decoration.from.eip55, value: appValue)])

            return EvmIncomingTransactionRecord(
                source: source,
                transaction: transaction,
                baseToken: baseToken,
                from: decoration.from.eip55,
                value: appValue,
                spam: spam
            )

        case let decoration as OutgoingDecoration:
            return EvmOutgoingTransactionRecord(
                source: source,
                transaction: transaction,
                baseToken: baseToken,
                to: decoration.to.eip55,
                value: baseAppValue(value: decoration.value, sign: .minus),
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
                amountIn: .exact(value: convertToAppValue(token: decoration.tokenIn, value: decoration.amountIn, sign: .minus)),
                amountOut: convertToAmount(token: decoration.tokenOut, amount: decoration.amountOut, sign: .plus),
                recipient: decoration.recipient?.eip55
            )

        case let decoration as OneInchUnoswapDecoration:
            return SwapTransactionRecord(
                source: source,
                transaction: transaction,
                baseToken: baseToken,
                exchangeAddress: decoration.contractAddress.eip55,
                amountIn: .exact(value: convertToAppValue(token: decoration.tokenIn, value: decoration.amountIn, sign: .minus)),
                amountOut: decoration.tokenOut.map { convertToAmount(token: $0, amount: decoration.amountOut, sign: .plus) },
                recipient: nil
            )

        case let decoration as OneInchUnknownSwapDecoration:
            return UnknownSwapTransactionRecord(
                source: source,
                transaction: transaction,
                baseToken: baseToken,
                exchangeAddress: decoration.contractAddress.eip55,
                valueIn: decoration.tokenAmountIn.map { convertToAppValue(token: $0.token, value: $0.value, sign: .minus) },
                valueOut: decoration.tokenAmountOut.map { convertToAppValue(token: $0.token, value: $0.value, sign: .plus) }
            )

        case let decoration as Eip721SafeTransferFromDecoration:
            return EvmOutgoingTransactionRecord(
                source: source,
                transaction: transaction,
                baseToken: baseToken,
                to: decoration.to.eip55,
                value: AppValue(
                    nftUid: .evm(blockchainType: source.blockchainType, contractAddress: decoration.contractAddress.hex, tokenId: decoration.tokenId.description),
                    tokenName: decoration.tokenInfo?.tokenName,
                    tokenSymbol: decoration.tokenInfo?.tokenSymbol,
                    value: convertAmount(amount: 1, decimals: 0, sign: .minus)
                ),
                sentToSelf: decoration.sentToSelf
            )

        case let decoration as Eip1155SafeTransferFromDecoration:
            return EvmOutgoingTransactionRecord(
                source: source,
                transaction: transaction,
                baseToken: baseToken,
                to: decoration.to.eip55,
                value: AppValue(
                    nftUid: .evm(blockchainType: source.blockchainType, contractAddress: decoration.contractAddress.hex, tokenId: decoration.tokenId.description),
                    tokenName: decoration.tokenInfo?.tokenName,
                    tokenSymbol: decoration.tokenInfo?.tokenSymbol,
                    value: convertAmount(amount: decoration.value, decimals: 0, sign: .minus)
                ),
                sentToSelf: decoration.sentToSelf
            )

        case let decoration as UnknownTransactionDecoration:
            let internalTransactions = decoration.internalTransactions.filter { $0.to == userAddress }

            let eip20Transfers = decoration.eventInstances.compactMap { $0 as? TransferEventInstance }
            let incomingEip20Transfers = eip20Transfers.filter { $0.to == userAddress && $0.from != userAddress }
            let outgoingEip20Transfers = eip20Transfers.filter { $0.from == userAddress }

            let eip721Transfers = decoration.eventInstances.compactMap { $0 as? Eip721TransferEventInstance }
            let incomingEip721Transfers = eip721Transfers.filter { $0.to == userAddress && $0.from != userAddress }
            let outgoingEip721Transfers = eip721Transfers.filter { $0.from == userAddress }

            let eip1155Transfers = decoration.eventInstances.compactMap { $0 as? Eip1155TransferEventInstance }
            let incomingEip1155Transfers = eip1155Transfers.filter { $0.to == userAddress && $0.from != userAddress }
            let outgoingEip1155Transfers = eip1155Transfers.filter { $0.from == userAddress }

            let incomingEvents = transferEvents(internalTransactions: internalTransactions) + transferEvents(incomingEip20Transfers: incomingEip20Transfers) + transferEvents(incomingEip721Transfers: incomingEip721Transfers) + transferEvents(incomingEip1155Transfers: incomingEip1155Transfers)
            let outgoingEvents = transferEvents(outgoingEip20Transfers: outgoingEip20Transfers) + transferEvents(outgoingEip721Transfers: outgoingEip721Transfers) + transferEvents(outgoingEip1155Transfers: outgoingEip1155Transfers)

            if transaction.from == userAddress, let contractAddress = transaction.to, let value = transaction.value {
                return ContractCallTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    contractAddress: contractAddress.eip55,
                    method: transaction.input.flatMap { evmLabelManager.methodLabel(input: $0) },
                    incomingEvents: incomingEvents,
                    outgoingEvents: transferEvents(contractAddress: contractAddress, value: value) + outgoingEvents
                )
            } else if transaction.from != userAddress, transaction.to != userAddress {
                let spam = SpamManager.isSpam(events: incomingEvents + outgoingEvents)

                return ExternalContractCallTransactionRecord(
                    source: source,
                    transaction: transaction,
                    baseToken: baseToken,
                    incomingEvents: incomingEvents,
                    outgoingEvents: outgoingEvents,
                    spam: spam
                )
            }

        default: ()
        }

        return EvmTransactionRecord(
            source: source,
            transaction: transaction,
            baseToken: baseToken,
            ownTransaction: transaction.from == userAddress
        )
    }
}
