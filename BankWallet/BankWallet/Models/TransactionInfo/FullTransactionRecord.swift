import Foundation

class FullTransactionRecord {
    let resource: String
    let url: String
    let sections: [FullTransactionSection]

    init(resource: String, url: String, sections: [FullTransactionSection]) {
        self.resource = resource
        self.url = url
        self.sections = sections
    }
}
