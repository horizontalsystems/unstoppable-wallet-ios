import Foundation
import GRDB

class SwapAssetStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
}

extension SwapAssetStorage {
    func swapAssetMap<T: Decodable>(provider: String, as type: T.Type) throws -> [String: T] {
        let swapAssets: [SwapAsset] = try dbPool.read { db in
            try SwapAsset.filter(SwapAsset.Columns.provider == provider).fetchAll(db)
        }

        return try Dictionary(uniqueKeysWithValues: swapAssets.map {
            try ($0.tokenQueryId, $0.decodedData(as: type))
        })
    }

    func lastSyncTimetamp(provider: String) throws -> TimeInterval? {
        try dbPool.read { db in
            try SwapAssetSyncInfo.filter(SwapAssetSyncInfo.Columns.provider == provider).fetchOne(db)?.lastSyncTimestamp
        }
    }

    func save(swapAssetMap: [String: some Encodable], provider: String) throws {
        _ = try dbPool.write { db in
            try SwapAsset.filter(SwapAsset.Columns.provider == provider).deleteAll(db)

            let swapAssets = try swapAssetMap.map {
                try SwapAsset(provider: provider, tokenQueryId: $0, data: $1)
            }

            for swapAsset in swapAssets {
                try swapAsset.insert(db)
            }
        }
    }

    func save(lastSyncTimestamp: TimeInterval, provider: String) throws {
        _ = try dbPool.write { db in
            let swapAssetSyncInfo = SwapAssetSyncInfo(provider: provider, lastSyncTimestamp: lastSyncTimestamp)
            try swapAssetSyncInfo.insert(db)
        }
    }
}
