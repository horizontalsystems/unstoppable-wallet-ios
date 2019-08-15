import Foundation

class EosTransactionInfoAdapter: IFullTransactionInfoAdapter {
    private static let gWeiCode = "GWei"

    private let provider: IEosProvider
    private let coin: Coin

    init(provider: IEosProvider, coin: Coin) {
        self.provider = provider
        self.coin = coin
    }

    func convert(json: [String: Any]) -> FullTransactionRecord? {
        guard let txResponse = provider.convert(json: json) else {
            return nil
        }

        var sections = [FullTransactionSection]()

        // Top Section

        var topSectionItems = [FullTransactionItem]()
        if let blockTime = txResponse.blockTime {
            topSectionItems.append(FullTransactionItem(icon: "Date Icon", title: "full_info.time".localized, value: DateHelper.instance.formatTransactionInfoTime(from: blockTime)))
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

        // From / To

        var inputOutputItems = [FullTransactionItem]()
        if let contract = txResponse.contract {
            inputOutputItems.append(FullTransactionItem(title: "full_info.contract".localized, value: contract, clickable: true, showExtra: .token))
        }
        if let quantity = txResponse.quantity {
            inputOutputItems.append(FullTransactionItem(title: "full_info.amount".localized, value: quantity))
        }
        if let from = txResponse.from {
            inputOutputItems.append(FullTransactionItem(title: "full_info.from".localized, value: from, clickable: true, showExtra: .icon))
        }
        if let to = txResponse.to {
            inputOutputItems.append(FullTransactionItem(title: "full_info.to".localized, value: to, clickable: true, showExtra: .icon))
        }
        if let memo = txResponse.memo, !memo.isEmpty {
            inputOutputItems.append(FullTransactionItem(title: "full_info.memo".localized, value: memo, clickable: true, showExtra: .none))
        }
        if !inputOutputItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: inputOutputItems))
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

        return FullTransactionRecord(providerName: provider.name, haveBlockExplorer: provider.url(for: "") != nil, sections: sections)
    }
}
