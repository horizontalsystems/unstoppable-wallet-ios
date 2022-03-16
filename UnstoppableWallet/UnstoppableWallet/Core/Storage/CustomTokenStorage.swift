import GRDB
import MarketKit

class CustomTokenStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension CustomTokenStorage {

    func customTokens(platformType: PlatformType, filter: String) -> [CustomToken] {
        try! dbPool.read { db in
            try CustomToken
                    .filter(CustomToken.Columns.coinName.like("%\(filter)%") || CustomToken.Columns.coinCode.like("%\(filter)%"))
                    .filter(platformType.coinTypeIdPrefixes.map { CustomToken.Columns.coinTypeId.like("\($0)%") }.joined(operator: .or))
                    .fetchAll(db)
        }
    }

    func customTokens(filter: String) -> [CustomToken] {
        try! dbPool.read { db in
            try CustomToken
                    .filter(CustomToken.Columns.coinName.like("%\(filter)%") || CustomToken.Columns.coinCode.like("%\(filter)%"))
                    .order(CustomToken.Columns.coinName.asc)
                    .fetchAll(db)
        }
    }

    func customTokens(coinTypeIds: [String]) -> [CustomToken] {
        try! dbPool.read { db in
            try CustomToken
                    .filter(coinTypeIds.contains(CustomToken.Columns.coinTypeId))
                    .fetchAll(db)
        }
    }

    func customToken(coinType: MarketKit.CoinType) -> CustomToken? {
        try! dbPool.read { db in
            try CustomToken
                    .filter(CustomToken.Columns.coinTypeId == coinType.id)
                    .fetchOne(db)
        }
    }

    func save(customTokens: [CustomToken]) {
        _ = try! dbPool.write { db in
            for customToken in customTokens {
                try customToken.insert(db)
            }
        }
    }

}
