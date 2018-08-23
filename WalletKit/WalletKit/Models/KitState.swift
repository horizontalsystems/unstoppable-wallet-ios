import Foundation
import RealmSwift

public class KitState: Object {

    @objc dynamic var uniqueStubField = ""
    @objc dynamic var apiSynced = false

    override public class func primaryKey() -> String? {
        return "uniqueStubField"
    }

}
