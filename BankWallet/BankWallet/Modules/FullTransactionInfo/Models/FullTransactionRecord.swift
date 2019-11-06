class FullTransactionRecord {
    let providerName: String
    let sections: [FullTransactionSection]

    init(providerName: String, sections: [FullTransactionSection]) {
        self.providerName = providerName
        self.sections = sections
    }
}
