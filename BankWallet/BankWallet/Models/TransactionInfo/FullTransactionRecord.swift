class FullTransactionRecord {
    let providerName: String
    let haveBlockExplorer: Bool
    let sections: [FullTransactionSection]

    init(providerName: String, haveBlockExplorer: Bool = true, sections: [FullTransactionSection]) {
        self.providerName = providerName
        self.haveBlockExplorer = haveBlockExplorer
        self.sections = sections
    }
}
