import Foundation

class UnspentOutputsManager {
    static let shared = UnspentOutputsManager()

    enum SelectorError: Error {
        case emptyOutputs
        case notEnough
    }

    let realmFactory: RealmFactory!

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func select(value: Int, outputs: [TransactionOutput]? = nil) throws -> [TransactionOutput] {
        let outputs = outputs ?? allUnspentOutputs()

        guard !outputs.isEmpty else {
            throw SelectorError.emptyOutputs
        }
        var selected = [TransactionOutput]()
        if let output = outputs.first(where: { $0.value == value }) {
            selected.append(output)
            return selected
        }
        let sortedOutputs = outputs.sorted(by: { lhs, rhs in lhs.value < rhs.value })

        var total = 0
        for output in sortedOutputs {
            if total >= value {
                break
            }
            selected.append(output)
            total += output.value
        }
        if total < value {
            throw SelectorError.notEnough
        }

        return selected
    }

    private func allUnspentOutputs() -> [TransactionOutput] {
        let realm = realmFactory.realm
        let allUnspentOutputs = realm.objects(TransactionOutput.self)
                .filter("isMine = %@", true)
                .filter("scriptType = %@ OR scriptType = %@", ScriptType.p2pkh.rawValue, ScriptType.p2pk.rawValue)
                .filter("inputs.@count = %@", 0)
                .filter("transaction != nil")

        return Array(allUnspentOutputs)
    }

}
