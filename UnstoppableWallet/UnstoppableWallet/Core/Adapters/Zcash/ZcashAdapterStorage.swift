import Foundation
import GRDB

class ZcashAdapterStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("create ZcashBalance") { db in
            try db.create(table: ZcashBalanceData.databaseTableName) { t in
                t.column(ZcashBalanceData.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(ZcashBalanceData.Columns.full.name, .text).notNull()
                t.column(ZcashBalanceData.Columns.available.name, .text).notNull()
                t.column(ZcashBalanceData.Columns.transparent.name, .text).notNull()
            }
        }

        migrator.registerMigration("create ZcashTransparentAlert") { db in
            try db.create(table: ZcashTransparentAlertState.databaseTableName) { t in
                t.column(ZcashTransparentAlertState.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(ZcashTransparentAlertState.Columns.lastAlertedBalance.name, .text).notNull()
            }
        }

        migrator.registerMigration("create SingleUseAddress") { db in
            try db.create(table: SingleUseAddress.databaseTableName) { t in
                t.autoIncrementedPrimaryKey(SingleUseAddress.Columns.rowId.rawValue)
                t.column(SingleUseAddress.Columns.walletId.name, .text).notNull()
                t.column(SingleUseAddress.Columns.address.name, .text).notNull()
                t.column(SingleUseAddress.Columns.gapIndex.name, .integer).notNull()
                t.column(SingleUseAddress.Columns.gapLimit.name, .integer).notNull()
                t.column(SingleUseAddress.Columns.timestamp.name, .datetime).notNull()
                t.column(SingleUseAddress.Columns.isUsed.name, .boolean).notNull().defaults(to: false)

                t.uniqueKey([
                    SingleUseAddress.Columns.walletId.name,
                    SingleUseAddress.Columns.address.name,
                ], onConflict: .replace)
            }
        }

        return migrator
    }
}

extension ZcashAdapterStorage {
    func save(balanceData: ZcashBalanceData) throws {
        try dbPool.write { db in
            try balanceData.insert(db)
        }
    }

    func balanceData(id: String) throws -> ZcashBalanceData? {
        try dbPool.read { db in
            try ZcashBalanceData
                .filter(ZcashBalanceData.Columns.id == id)
                .fetchOne(db)
        }
    }

    func delete(id: String) throws {
        _ = try dbPool.write { db in
            try ZcashBalanceData
                .filter(ZcashBalanceData.Columns.id == id)
                .deleteAll(db)
        }
    }

    func clear() throws {
        _ = try dbPool.write { db in
            try ZcashBalanceData.deleteAll(db)
        }
    }
}

extension ZcashAdapterStorage {
    func save(state: ZcashTransparentAlertState) throws {
        try dbPool.write { db in
            try state.insert(db)
        }
    }

    func alertState(id: String) throws -> ZcashTransparentAlertState? {
        try dbPool.read { db in
            try ZcashTransparentAlertState
                .filter(ZcashTransparentAlertState.Columns.id == id)
                .fetchOne(db)
        }
    }

    func deleteAlertState(id: String) throws {
        _ = try dbPool.write { db in
            try ZcashTransparentAlertState
                .filter(ZcashTransparentAlertState.Columns.id == id)
                .deleteAll(db)
        }
    }
}

extension ZcashAdapterStorage {
    @discardableResult func save(address: SingleUseAddress) throws -> SingleUseAddress {
        var mutableAddress = address
        try dbPool.write { db in
            try mutableAddress.insert(db)
        }

        return mutableAddress
    }

    func update(address: SingleUseAddress) throws {
        try dbPool.write { db in
            try address.update(db)
        }
    }

    func all(walletId: String, unused: Bool = false) throws -> [SingleUseAddress] {
        try dbPool.read { db in
            var request = SingleUseAddress
                .filter(SingleUseAddress.Columns.walletId == walletId)

            if unused {
                request = request.filter(SingleUseAddress.Columns.isUsed == false)
            }

            return try request
                .order(SingleUseAddress.Columns.rowId.asc)
                .fetchAll(db)
        }
    }

    func firstUnused(walletId: String) throws -> SingleUseAddress? {
        try dbPool.read { db in
            let lastUsed = try SingleUseAddress
                .filter(SingleUseAddress.Columns.walletId == walletId)
                .filter(SingleUseAddress.Columns.isUsed == true)
                .order(SingleUseAddress.Columns.rowId.asc)
                .fetchAll(db)
                .last

            return try SingleUseAddress
                .filter(SingleUseAddress.Columns.walletId == walletId)
                .filter(SingleUseAddress.Columns.rowId > lastUsed?.rowId ?? -1)
                .order(SingleUseAddress.Columns.rowId.asc)
                .fetchAll(db)
                .first
        }
    }

    func address(_ address: String, walletId: String) throws -> SingleUseAddress? {
        try dbPool.read { db in
            try SingleUseAddress
                .filter(SingleUseAddress.Columns.walletId == walletId)
                .filter(SingleUseAddress.Columns.address == address)
                .fetchOne(db)
        }
    }

    func addresses(walletId: String, before address: String, unused: Bool = false) throws -> [SingleUseAddress] {
        guard let referenceAddress = try self.address(address, walletId: walletId),
              let refRowId = referenceAddress.rowId
        else {
            return []
        }

        return try dbPool.read { db in
            var request = SingleUseAddress
                .filter(SingleUseAddress.Columns.walletId == walletId)
                .filter(SingleUseAddress.Columns.rowId < refRowId)

            if unused {
                request = request.filter(SingleUseAddress.Columns.isUsed == false)
            }

            return try request
                .order(SingleUseAddress.Columns.rowId.asc)
                .fetchAll(db)
        }
    }

    func addresses(walletId: String, after address: String?, unused: Bool = false) throws -> [SingleUseAddress] {
        var refRowId: Int64?

        if let address, let referenceAddress = try self.address(address, walletId: walletId),
           let id = referenceAddress.rowId
        {
            refRowId = id
        }

        return try dbPool.read { db in
            var request = SingleUseAddress
                .filter(SingleUseAddress.Columns.walletId == walletId)

            if let refRowId {
                request = request.filter(SingleUseAddress.Columns.rowId > refRowId)
            }

            if unused {
                request = request.filter(SingleUseAddress.Columns.isUsed == false)
            }

            return try request
                .order(SingleUseAddress.Columns.rowId.asc)
                .fetchAll(db)
        }
    }

    func lastUsedAddress(walletId: String) throws -> SingleUseAddress? {
        try dbPool.read { db in
            try SingleUseAddress
                .filter(SingleUseAddress.Columns.walletId == walletId)
                .filter(SingleUseAddress.Columns.isUsed == true)
                .order(SingleUseAddress.Columns.rowId.desc)
                .fetchOne(db)
        }
    }

    @discardableResult func clear(walletId: String) throws -> Int {
        try dbPool.write { db in
            try SingleUseAddress
                .filter(SingleUseAddress.Columns.walletId == walletId)
                .deleteAll(db)
        }
    }
}
