import Foundation

class EosTransactionInfoAdapter: IFullTransactionInfoAdapter {
    private static let gWeiCode = "GWei"

    private let provider: IEosProvider
    private let wallet: Wallet

    init(provider: IEosProvider, wallet: Wallet) {
        self.provider = provider
        self.wallet = wallet
    }

    func convert(json: [String: Any]) -> FullTransactionRecord? {
        guard case let .eos(account, _) = wallet.account.type else {
            return nil
        }

        guard let txResponse = provider.convert(json: json, account: account) else {
            return nil
        }

        var sections = [FullTransactionSection]()

        // Top Section

        var topSectionItems = [FullTransactionItem]()
        if let blockTime = txResponse.blockTime {
            topSectionItems.append(FullTransactionItem(icon: "Date Icon", title: "full_info.time".localized, value: DateHelper.instance.formatFullTime(from: blockTime)))
        }
        if let blockNumber = txResponse.blockNumber {
            topSectionItems.append(FullTransactionItem(icon: "Block Icon", title: "full_info.block".localized, value: "#\(blockNumber)"))
        }
        if let status = txResponse.status {
            topSectionItems.append(FullTransactionItem(icon: "Confirmations Icon", title: "full_info.status".localized, value: "\(status)"))
        }
        if !topSectionItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: topSectionItems))
        }

        // Actions
        
        for action in txResponse.actions {
            var inputOutputItems = [FullTransactionItem]()
            if let contract = action.contract {
                inputOutputItems.append(FullTransactionItem(title: "full_info.contract".localized, value: contract, clickable: true, showExtra: .token))
            }
            if let quantity = action.quantity {
                inputOutputItems.append(FullTransactionItem(title: "full_info.amount".localized, value: quantity))
            }
            if let from = action.from {
                inputOutputItems.append(FullTransactionItem(title: "full_info.from".localized, value: from, clickable: true, showExtra: .icon))
            }
            if let to = action.to {
                inputOutputItems.append(FullTransactionItem(title: "full_info.to".localized, value: to, clickable: true, showExtra: .icon))
            }
            if let memo = action.memo, !memo.isEmpty {
                inputOutputItems.append(FullTransactionItem(title: "full_info.memo".localized, value: memo, clickable: true, showExtra: .none))
            }
            if !inputOutputItems.isEmpty {
                sections.append(FullTransactionSection(title: nil, items: inputOutputItems))
            }
        }
        
        // net and cpu

        var netCpuItems = [FullTransactionItem]()
        if let cpu = txResponse.cpuUsage {
            netCpuItems.append(FullTransactionItem(title: "full_info.cpu".localized, value: "full_info.milli_seconds".localized("\(cpu)")))
        }
        if let net = txResponse.netUsage {
            netCpuItems.append(FullTransactionItem(title: "full_info.net".localized, value: "full_info.bytes".localized("\(net * 8)")))
        }
        if !netCpuItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: netCpuItems))
        }

        return FullTransactionRecord(providerName: provider.name, sections: sections)
    }

}
