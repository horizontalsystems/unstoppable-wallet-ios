import Foundation

class AuthData: NSObject, NSCoding {
    private static let walletIdKey = "walletId"
    private static let wordsKey = "words"

    let walletId: String
    let words: [String]

    init(words: [String], walletId: String? = nil) {
        self.walletId = walletId ?? UUID().uuidString
        self.words = words
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard let walletId = aDecoder.decodeObject(forKey: AuthData.walletIdKey) as? String else {
            return nil
        }
        guard let words = aDecoder.decodeObject(forKey: AuthData.wordsKey) as? [String] else {
            return nil
        }

        self.init(words: words, walletId: walletId)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(walletId, forKey: AuthData.walletIdKey)
        aCoder.encode(words, forKey: AuthData.wordsKey)
    }

}
