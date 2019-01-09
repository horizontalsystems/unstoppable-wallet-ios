import Foundation

protocol IFullTransactionInfoAdapter {
    var url: String { get }
    func convert(json: [String: Any]) -> FullTransactionRecord?
}

class BitcoinTransactionInfoAdapter: IFullTransactionInfoAdapter {
    private let converter: IBitcoinJSONConverter
    private let coinCode: String

    init(jsonConverter: IBitcoinJSONConverter, coinCode: String) {
        self.converter = jsonConverter
        self.coinCode = coinCode
    }

    var url: String {
        return converter.url
    }

    func convert(json: [String: Any]) -> FullTransactionRecord? {
        guard let txResponse = converter.convert(json: json) else {
            return nil
        }

        var sections = [FullTransactionSection]()

        // tx Id
        if let txId = txResponse.txId {
            let idItems = [FullTransactionItem(title: "full_info.id".localized, value: txId, clickable: true, showExtra: .hash)]
            sections.append(FullTransactionSection(title: nil, items: idItems))
        }

        // BLOCK
        var blockItems = [FullTransactionItem]()
        if let blockTime = txResponse.blockTime, let time = TimeInterval(exactly: blockTime) {
            let blockDate = Date(timeIntervalSince1970: time)
            blockItems.append(FullTransactionItem(title: "full_info.time".localized, value: DateHelper.instance.formatTransactionInfoTime(from: blockDate)))
        }

        if let blockHeight = txResponse.blockHeight {
            blockItems.append(FullTransactionItem(title: "full_info.block".localized, value: "\(blockHeight)"))
        }

        if let confirmations = txResponse.confirmations {
            blockItems.append(FullTransactionItem(title: "full_info.confirmations".localized, value: "\(confirmations)"))
        }
        if !blockItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: blockItems))
        }

        // TRANSACTION
        var transactionItems = [FullTransactionItem]()
        if !txResponse.inputs.isEmpty {
            let totalInputs = txResponse.inputs.reduce(0) { $0 + $1.value }
            if let formatted = ValueFormatter.instance.format(amount: totalInputs) {
                transactionItems.append(FullTransactionItem(title: "full_info.total_input".localized, value: "\(formatted) \(coinCode)"))
            }
        }

        if !txResponse.outputs.isEmpty {
            let totalOutputs = txResponse.outputs.reduce(0) { $0 + $1.value }
            if let formatted = ValueFormatter.instance.format(amount: totalOutputs) {
                transactionItems.append(FullTransactionItem(title: "full_info.total_output".localized, value: "\(formatted) \(coinCode)"))
            }
        }
        if let size = txResponse.size {
            transactionItems.append(FullTransactionItem(title: "full_info.size".localized, value: "\(size) \("full_info.bytes".localized)"))
        }
        if let fee = txResponse.fee, let formatted = ValueFormatter.instance.format(amount: fee) {
            transactionItems.append(FullTransactionItem(title: "full_info.fee".localized, value: "\(formatted) \(coinCode)"))
        }
        if let feeRate = txResponse.feePerByte, let formatted = ValueFormatter.instance.format(amount: feeRate) {
            transactionItems.append(FullTransactionItem(title: "full_info.fee_rate".localized, value: "\(formatted) \("full_info.sat_byte".localized)"))
        }
        if !transactionItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: transactionItems))
        }

        // INPUTS
        var inputItems = [FullTransactionItem]()
        for input in txResponse.inputs {
            if let formatted = ValueFormatter.instance.format(amount: input.value) {
                let clickable = input.address != nil
                inputItems.append(FullTransactionItem(title: "\(formatted) \(coinCode)", value: input.address ?? "not available", clickable: clickable, showExtra: clickable ? .icon : .none))
            }
        }
        if !inputItems.isEmpty {
            sections.append(FullTransactionSection(title: "full_info.subtitle_inputs".localized, items: inputItems))
        }

        // OUTPUTS
        var outputItems = [FullTransactionItem]()
        for output in txResponse.outputs {
            if let formatted = ValueFormatter.instance.format(amount: output.value) {
                let clickable = output.address != nil
                let address = output.address ?? "not available"
                outputItems.append(FullTransactionItem(title: "\(formatted) \(coinCode)", value: address, clickable: clickable, showExtra: clickable ? .icon : .none))
            }
        }
        if !outputItems.isEmpty {
            sections.append(FullTransactionSection(title: "full_info.subtitle_outputs".localized, items: outputItems))
        }

        return FullTransactionRecord(resource: converter.resource, url: url, sections: sections)
    }
}

class EthereumTransactionInfoAdapter: IFullTransactionInfoAdapter {
    private let converter: IEthereumJSONConverter
    private let coinCode: String

    init(jsonConverter: IEthereumJSONConverter, coinCode: String) {
        self.converter = jsonConverter
        self.coinCode = coinCode
    }

    var url: String {
        return converter.url
    }

    func convert(json: [String: Any]) -> FullTransactionRecord? {
        guard let txResponse = converter.convert(json: json) else {
            return nil
        }

        var sections = [FullTransactionSection]()

        // tx Id
        if let txId = txResponse.txId {
            let idItems = [FullTransactionItem(title: "full_info.id".localized, value: txId, clickable: true, showExtra: .hash)]
            sections.append(FullTransactionSection(title: nil, items: idItems))
        }

        // BLOCK
        var blockItems = [FullTransactionItem]()
        if let blockTime = txResponse.blockTime, let time = TimeInterval(exactly: blockTime) {
            let blockDate = Date(timeIntervalSince1970: time)
            blockItems.append(FullTransactionItem(title: "full_info.time".localized, value: DateHelper.instance.formatTransactionInfoTime(from: blockDate)))
        }

        if let blockHeight = txResponse.blockHeight {
            blockItems.append(FullTransactionItem(title: "full_info.block".localized, value: "\(blockHeight)"))
        }

        if let confirmations = txResponse.confirmations {
            blockItems.append(FullTransactionItem(title: "full_info.confirmations".localized, value: "\(confirmations)"))
        }
        if !blockItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: blockItems))
        }

        // TRANSACTION
        var transactionItems = [FullTransactionItem]()
        if let size = txResponse.size {
            transactionItems.append(FullTransactionItem(title: "full_info.size".localized, value: "\(size) \("full_info.bytes".localized)"))
        }
        if let gasLimit = txResponse.gasLimit, let formatted = ValueFormatter.instance.format(amount: gasLimit) {
            transactionItems.append(FullTransactionItem(title: "Gas Limit".localized, value: "\(formatted) GWei"))
        }
        if let gasUsed = txResponse.gasUsed, let formatted = ValueFormatter.instance.format(amount: gasUsed) {
            transactionItems.append(FullTransactionItem(title: "Gas Used".localized, value: "\(formatted) GWei"))
        }
        if let gasPrice = txResponse.gasPrice, let formatted = ValueFormatter.instance.format(amount: gasPrice) {
            transactionItems.append(FullTransactionItem(title: "Gas Price".localized, value: "\(formatted) GWei"))
        }
        if !transactionItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: transactionItems))
        }

        var inputOutputItems = [FullTransactionItem]()
        if let nonce = txResponse.nonce {
            inputOutputItems.append(FullTransactionItem(title: "Nonce".localized, value: "\(nonce)"))
        }
        if let value = txResponse.value {
            inputOutputItems.append(FullTransactionItem(title: "Value".localized, value: "\(value) \(coinCode)"))
        }
        if let from = txResponse.from {
            inputOutputItems.append(FullTransactionItem(title: "From".localized, value: from, clickable: true, showExtra: .icon))
        }
        if let to = txResponse.to {
            inputOutputItems.append(FullTransactionItem(title: "To".localized, value: to, clickable: true, showExtra: .icon))
        }
        if !inputOutputItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: inputOutputItems))
        }

        return FullTransactionRecord(resource: converter.resource, url: url, sections: sections)
    }
}
