class TransactionRecordPool {
    private(set) var state: TransactionRecordPoolState

    init(state: TransactionRecordPoolState) {
        self.state = state
    }

    var coin: Coin {
        return state.coin
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

        let hashFrom = state.records.last?.transactionHash
        let fetchLimit = limit + 1 - unusedRecordsCount

        return FetchData(coin: state.coin, hashFrom: hashFrom, limit: fetchLimit)
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
        } else if state.allLoaded && unusedRecords.isEmpty {
            state.add(records: [record])
            return .newData
        }

        return .ignored
    }

}

enum HandleResult {
    case updated, inserted,  newData, ignored
}
