import Foundation

class BalanceHelper {
    static let shared = BalanceHelper()

    let realmFactory: RealmFactory!

    init(realmFactory: RealmFactory = .shared) {
        self.realmFactory = realmFactory
    }

    func allUnspentOutputs() -> [TransactionOutput] {
        let realm = realmFactory.realm
        let allUnspentOutputs = realm.objects(TransactionOutput.self)
                .filter("isMine = %@", true)
                .filter("scriptType = %@ OR scriptType = %@", ScriptType.p2pkh.rawValue, ScriptType.p2pk.rawValue)
                .filter("inputs.@count = %@", 0)

        return Array(allUnspentOutputs)
    }

}
