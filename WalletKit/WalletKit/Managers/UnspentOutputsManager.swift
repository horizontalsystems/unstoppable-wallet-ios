import Foundation

class UnspentOutputManager {
    enum SelectorError: Error {
        case emptyOutputs
        case notEnough
    }

    let realmFactory: RealmFactory!

    init(realmFactory: RealmFactory) {
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

    func balance(outputs: [TransactionOutput]? = nil) -> Int {
        let outputs = outputs ?? allUnspentOutputs()

        return outputs.reduce(0) { $0 + $1.value }
    }

    private func allUnspentOutputs() -> [TransactionOutput] {
        let realm = realmFactory.realm
        let allUnspentOutputs = realm.objects(TransactionOutput.self)
                .filter("isMine = %@", true)
                .filter("scriptType = %@ OR scriptType = %@", ScriptType.p2pkh.rawValue, ScriptType.p2pk.rawValue)
                .filter("inputs.@count = %@", 0)
                .filter("transactions.@count > %@", 0)

        return Array(allUnspentOutputs)
    }

}
