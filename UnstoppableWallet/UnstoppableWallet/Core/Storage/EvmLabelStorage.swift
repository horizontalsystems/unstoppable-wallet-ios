import GRDB

class EvmLabelStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension EvmLabelStorage {

    func evmMethodLabel(methodId: String) throws -> EvmMethodLabel? {
        try dbPool.read { db in
            try EvmMethodLabel.filter(EvmMethodLabel.Columns.methodId == methodId).fetchOne(db)
        }
    }

    func save(evmMethodLabels: [EvmMethodLabel]) throws {
        _ = try dbPool.write { db in
            try EvmMethodLabel.deleteAll(db)

            for label in evmMethodLabels {
                try label.insert(db)
            }
        }
    }

    func evmAddressLabel(address: String) throws -> EvmAddressLabel? {
        try dbPool.read { db in
            try EvmAddressLabel.filter(EvmAddressLabel.Columns.address == address).fetchOne(db)
        }
    }

    func save(evmAddressLabels: [EvmAddressLabel]) throws {
        _ = try dbPool.write { db in
            try EvmAddressLabel.deleteAll(db)

            for label in evmAddressLabels {
                try label.insert(db)
            }
        }
    }

}
