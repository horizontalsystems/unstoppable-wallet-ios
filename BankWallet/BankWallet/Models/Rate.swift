import RealmSwift

class Rate: Object {
    @objc dynamic var coin: String = ""
    @objc dynamic var currencyCode: String = ""
    @objc dynamic var value: Double = 0
    @objc dynamic var timestamp: Double = 0

    var expired: Bool {
        let diff = Date().timeIntervalSince1970 - timestamp
        return diff > 60 * 10
    }
}
