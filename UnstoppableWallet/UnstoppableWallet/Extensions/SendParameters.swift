import BitcoinCore

extension SendParameters {
    func copy() -> SendParameters {
        SendParameters(
            address: address,
            value: value,
            feeRate: feeRate,
            sortType: sortType,
            senderPay: senderPay,
            rbfEnabled: rbfEnabled,
            memo: memo,
            unspentOutputs: unspentOutputs,
            pluginData: pluginData,
            utxoFilters: utxoFilters,
            changeToFirstInput: changeToFirstInput
        )
    }
}
