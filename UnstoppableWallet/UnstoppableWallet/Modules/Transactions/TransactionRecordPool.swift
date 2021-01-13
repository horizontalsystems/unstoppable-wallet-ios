class TransactionRecordPool {
    private(set) var state: TransactionRecordPoolState

    init(state: TransactionRecordPoolState) {
        self.state = state
    }

    var wallet: Wallet {
        return state.wallet
    }

    var records: [TransactionRecord] {
        return state.records
    }

    var allShown: Bool {
        return state.allLoaded && state.unusedRecords.isEmpty
    }

    var unusedRecords: [TransactionRecord] {
        return state.unusedRecords
    }

    func increaseFirstUnusedIndex() {
        state.firstUnusedIndex += 1
    }

    func resetFirstUnusedIndex() {
        state.firstUnusedIndex = 0
    }

    func getFetchData(limit: Int) -> FetchData? {
        guard !state.allLoaded else {
            return nil
        }

        let unusedRecordsCount = state.unusedRecords.count

        guard unusedRecordsCount <= limit else {
            return nil
        }

        let fetchLimit = limit + 1 - unusedRecordsCount

        return FetchData(wallet: state.wallet, from: state.records.last, limit: fetchLimit)
    }

    func add(records: [TransactionRecord]) {
        if records.isEmpty {
            state.allLoaded = true
        } else {
            state.add(records: records)
        }
    }

    func handleUpdated(record: TransactionRecord) -> HandleResult {
        if let index = state.index(ofRecord: record) {
            state.set(record: record, atIndex: index)

            if index < state.firstUnusedIndex {
                return .updated
            }
        } else if let index = state.insertIndex(ofRecord: record) {
            state.insert(record: record, atIndex: index)

            if index < state.firstUnusedIndex {
                increaseFirstUnusedIndex()
                return .inserted
            } else if index == 0 {
                return .newData
            }
        } else if state.allLoaded {
            state.add(records: [record])
            return .newData
        }

        return .ignored
    }

}

enum HandleResult {
    case updated, inserted,  newData, ignored
}
