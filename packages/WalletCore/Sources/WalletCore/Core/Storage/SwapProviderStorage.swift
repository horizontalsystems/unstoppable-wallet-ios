import Foundation
import GRDB

public class SwapProviderStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension SwapProviderStorage {
    /// In the order the server listed them.
    func providers() throws -> [SwapProviderRecord] {
        try dbPool.read { db in
            try SwapProviderRecord.order(SwapProviderRecord.Columns.position).fetchAll(db)
        }
    }

    /// Nil until a sync has stored a list. Every row of one sync carries the same timestamp.
    func lastSyncTimestamp() throws -> TimeInterval? {
        try dbPool.read { db in
            try SwapProviderRecord.fetchAll(db).map(\.lastSyncTimestamp).min()
        }
    }

    /// Whole-list replace: a provider the server stops listing must disappear, so a partial upsert
    /// would be wrong.
    func save(providers: [SwapProviderRecord]) throws {
        _ = try dbPool.write { db in
            try SwapProviderRecord.deleteAll(db)

            for provider in providers {
                try provider.insert(db)
            }
        }
    }
}
