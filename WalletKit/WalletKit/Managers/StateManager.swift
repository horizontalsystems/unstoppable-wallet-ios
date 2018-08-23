import Foundation
import RealmSwift

class StateManager {

    private let realmFactory: RealmFactory

    init(realmFactory: RealmFactory) {
        self.realmFactory = realmFactory
    }

    var apiSynced: Bool {
        get {
            return getKitState().apiSynced
        }
        set {
            setKitState { kitState in
                kitState.apiSynced = newValue
            }
        }
    }

    private func getKitState() -> KitState {
        return realmFactory.realm.objects(KitState.self).first ?? KitState()
    }

    private func setKitState(_ block: (KitState) -> ()) {
        let realm = realmFactory.realm

        let kitState = realm.objects(KitState.self).first ?? KitState()

        try? realm.write {
            block(kitState)
            realm.add(kitState, update: true)
        }
    }

}
