import GRDB
import ObjectMapper

class EvmAddressLabel: Record, ImmutableMappable {
    let address: String
    let label: String

    init(address: String, label: String) {
        self.address = address
        self.label = label

        super.init()
    }

    override class var databaseTableName: String {
        "evm_address_labels"
    }

    enum Columns: String, ColumnExpression {
        case address
        case label
    }

    required init(map: Map) throws {
        address = (try map.value("address") as String).lowercased()
        label = try map.value("label")

        super.init()
    }

    required init(row: Row) {
        address = row[Columns.address]
        label = row[Columns.label]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.address] = address
        container[Columns.label] = label
    }

}
