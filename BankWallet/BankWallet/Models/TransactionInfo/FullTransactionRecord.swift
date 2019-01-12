import Foundation

class FullTransactionRecord {
    let sections: [FullTransactionSection]

    init(sections: [FullTransactionSection]) {
        self.sections = sections
    }
}
