import Foundation

class BitcoinTransactionInfoAdapter: IFullTransactionInfoAdapter {
    private let provider: IBitcoinForksProvider
    private let coin: Coin

    init(provider: IBitcoinForksProvider, coin: Coin) {
        self.provider = provider
        self.coin = coin
    }

    func convert(json: [String: Any]) -> FullTransactionRecord? {
        guard let txResponse = provider.convert(json: json) else {
            return nil
        }

        var sections = [FullTransactionSection]()

        // BLOCK
        var blockItems = [FullTransactionItem]()

        if let blockTime = txResponse.blockTime, let time = TimeInterval(exactly: blockTime) {
            let blockDate = Date(timeIntervalSince1970: time)
            blockItems.append(FullTransactionItem(icon: "Date Icon", title: "full_info.time".localized, value: DateHelper.instance.formatTransactionInfoTime(from: blockDate)))
        }
        if let blockHeight = txResponse.blockHeight {
            blockItems.append(FullTransactionItem(icon: "Block Icon", title: "full_info.block".localized, value: "#\(blockHeight)"))
        }
        if let confirmations = txResponse.confirmations {
            blockItems.append(FullTransactionItem(icon: "Confirmations Icon", title: "full_info.confirmations".localized, value: "\(confirmations)"))
        }
        if !blockItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: blockItems))
        }

        // TRANSACTION
        var transactionItems = [FullTransactionItem]()
        if let fee = txResponse.fee {
            let feeValue = CoinValue(coinCode: coin.code, value: fee)
            transactionItems.append(FullTransactionItem(title: "full_info.fee".localized, value: ValueFormatter.instance.format(coinValue: feeValue)))
        }
        if let size = txResponse.size {
            transactionItems.append(FullTransactionItem(title: "full_info.size".localized, titleColor: .cryptoGray, value: "\(size) (bytes)"))
        }
        if let feeRate = txResponse.feePerByte {
            let feeRateValue = (ValueFormatter.instance.format(twoDigitValue: feeRate) ?? "") + " (satoshi)"
            transactionItems.append(FullTransactionItem(title: "full_info.rate".localized, titleColor: .cryptoGray, value: feeRateValue))
        }
        if !transactionItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: transactionItems))
        }

        //  INPUTS
        var inputItems = [FullTransactionItem]()
        if !txResponse.inputs.isEmpty {
            let totalInputs = txResponse.inputs.reduce(0) { $0 + $1.value }
            let totalValue = CoinValue(coinCode: coin.code, value: totalInputs)

            inputItems.append(FullTransactionItem(title: "full_info.inputs".localized, value: ValueFormatter.instance.format(coinValue: totalValue)))
        }
        for input in txResponse.inputs {
            guard let title = ValueFormatter.instance.format(coinValue: CoinValue(coinCode: coin.code, value: input.value)) else {
                continue
            }
            let clickable = input.address != nil
            inputItems.append(FullTransactionItem(title: title, value: input.address ?? "full_info.no_address", clickable: clickable, showExtra: clickable ? .icon : .none))
        }
        if !inputItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: inputItems))
        }

        //  OUTPUTS
        var outputItems = [FullTransactionItem]()
        if !txResponse.outputs.isEmpty {
            let totalOutputs = txResponse.outputs.reduce(0) { $0 + $1.value }
            let totalValue = CoinValue(coinCode: coin.code, value: totalOutputs)

            outputItems.append(FullTransactionItem(title: "full_info.outputs".localized, value: ValueFormatter.instance.format(coinValue: totalValue)))
        }
        for output in txResponse.outputs {
            guard let title = ValueFormatter.instance.format(coinValue: CoinValue(coinCode: coin.code, value: output.value)) else {
                continue
            }
            let clickable = output.address != nil
            let address = output.address ?? "full_info.no_address".localized
            outputItems.append(FullTransactionItem(title: title, value: address, clickable: clickable, showExtra: clickable ? .icon : .none))
        }
        if !outputItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: outputItems))
        }

        return FullTransactionRecord(providerName: provider.name, sections: sections)
    }
}
