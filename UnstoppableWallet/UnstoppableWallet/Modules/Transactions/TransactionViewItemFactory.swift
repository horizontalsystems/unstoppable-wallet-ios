import Foundation
import CurrencyKit
import CoinKit

class TransactionViewItemFactory: ITransactionViewItemFactory {

    private func coinString(from coinValue: CoinValue) -> String {
        ValueFormatter.instance.format(coinValue: coinValue, fractionPolicy: .threshold(high: 0.01, low: 0)) ?? ""
    }

    func currencyString(from currencyValue: CurrencyValue) -> String {
        ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: .threshold(high: 1000, low: 0.01)) ?? ""
    }
    
    func nameOrAddress(address: String) -> String {
        TransactionInfoAddressMapper.title(value: address) ?? String(address.prefix(5)) + "..." + String(address.suffix(5))
    }

    private func transactionType(record: TransactionRecord, lastBlockInfo: LastBlockInfo?) -> TransactionViewItem.TransactionType {
        switch record {
            case let evmIncoming as EvmIncomingTransactionRecord:
                return .incoming(from: nameOrAddress(address: evmIncoming.from), amount: coinString(from: evmIncoming.value), lockState: nil, conflictingTxHash: nil)

            case let evmOutgoing as EvmOutgoingTransactionRecord:
                return .outgoing(to: nameOrAddress(address: evmOutgoing.to), amount: coinString(from: evmOutgoing.value), lockState: nil, conflictingTxHash: nil, sentToSelf: evmOutgoing.sentToSelf)
                
            case let swap as SwapTransactionRecord:
                return .swap(exchangeAddress: nameOrAddress(address: swap.exchangeAddress), amountIn: coinString(from: swap.valueIn), amountOut: swap.valueOut.flatMap { coinString(from: $0) }, foreignRecipient: swap.foreignRecipient)
                
            case let approve as ApproveTransactionRecord:
                return .approve(spender: nameOrAddress(address: approve.spender), amount: coinString(from: approve.value), isMaxAmount: approve.value.isMaxValue)
                
            case let contractCall as ContractCallTransactionRecord:
                return .contractCall(contractAddress: nameOrAddress(address: contractCall.contractAddress), method: contractCall.method)
                
            case is ContractCreationTransactionRecord:
                return .contractCreation
                
            case let btcIncoming as BitcoinIncomingTransactionRecord:
                let lState = btcIncoming.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp)
                
                return .incoming(from: btcIncoming.from.flatMap { nameOrAddress(address: $0) }, amount: coinString(from: btcIncoming.value), lockState: lState, conflictingTxHash: btcIncoming.conflictingHash)
                
            case let btcOutgoing as BitcoinOutgoingTransactionRecord:
                let lState = btcOutgoing.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp)
                
                return .outgoing(to: btcOutgoing.to.flatMap { nameOrAddress(address: $0) }, amount: coinString(from: btcOutgoing.value), lockState: lState, conflictingTxHash: btcOutgoing.conflictingHash, sentToSelf: btcOutgoing.sentToSelf)
                
            default:
                fatalError("Record must be associated with TransactionType")
        }
    }

    func filterItems(wallets: [Wallet]) -> [FilterHeaderView.ViewItem] {
        if wallets.count < 2 {
            return []
        } else {
            return [.all] + wallets.map { .item(title: $0.coin.code) }
        }
    }

    func viewItem(fromRecord record: TransactionRecord, wallet: TransactionWallet, lastBlockInfo: LastBlockInfo? = nil, mainAmountCurrencyValue: CurrencyValue? = nil) -> TransactionViewItem {
        TransactionViewItem(
                wallet: wallet,
                record: record,
                type: transactionType(record: record, lastBlockInfo: lastBlockInfo),
                date: record.date,
                status: record.status(lastBlockHeight: lastBlockInfo?.height),
                mainAmountCurrencyString: mainAmountCurrencyValue.flatMap { currencyString(from: $0) }
        )
    }

    func viewStatus(adapterStates: [AdapterState], transactionsCount: Int) -> TransactionViewStatus {
        let noTransactions = transactionsCount == 0
        var upToDate = true

        adapterStates.forEach {
            if case .syncing = $0 {
                upToDate = false
            }
        }

        return TransactionViewStatus(showProgress: !upToDate, showMessage: noTransactions)
    }

}
