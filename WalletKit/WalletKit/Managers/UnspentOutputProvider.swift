import Foundation

class UnspentOutputProvider {

    let realmFactory: RealmFactory

    init(realmFactory: RealmFactory) {
        self.realmFactory = realmFactory
    }

    func allUnspentOutputs() -> [TransactionOutput] {
        let realm = realmFactory.realm
        let allUnspentOutputs = realm.objects(TransactionOutput.self)
                .filter("address != nil")
                .filter("scriptType = %@ OR scriptType = %@", ScriptType.p2pkh.rawValue, ScriptType.p2pk.rawValue)
                .filter("inputs.@count = %@", 0)

        return Array(allUnspentOutputs)
    }

}
