import GRDB
import ObjectMapper

class EvmMethodLabel: Record, ImmutableMappable {
    let methodId: String
    let label: String

    init(methodId: String, label: String) {
        self.methodId = methodId
        self.label = label

        super.init()
    }

    override class var databaseTableName: String {
        "evm_method_labels"
    }

    enum Columns: String, ColumnExpression {
        case methodId
        case label
    }

    required init(map: Map) throws {
        methodId = (try map.value("method_id") as String).lowercased()
        label = try map.value("label")

        super.init()
    }

    required init(row: Row) {
        methodId = row[Columns.methodId]
        label = row[Columns.label]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.methodId] = methodId
        container[Columns.label] = label
    }

}
