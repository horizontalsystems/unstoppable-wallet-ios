import Foundation

class KdfParams: Codable {
    static var defaultBackup = KdfParams(dklen: 32, n: 16384, p: 4, r: 8, salt: AppConfig.backupSalt)

    let dklen: Int
    let n: UInt64
    let p: UInt32
    let r: UInt32
    let salt: String

    enum CodingKeys: String, CodingKey {
        case dklen
        case n
        case p
        case r
        case salt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dklen = try container.decode(Int.self, forKey: .dklen)
        n = try container.decode(UInt64.self, forKey: .n)
        p = try container.decode(UInt32.self, forKey: .p)
        r = try container.decode(UInt32.self, forKey: .r)
        salt = try container.decode(String.self, forKey: .salt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dklen, forKey: .dklen)
        try container.encode(n, forKey: .n)
        try container.encode(p, forKey: .p)
        try container.encode(r, forKey: .r)
        try container.encode(salt, forKey: .salt)
    }

    init(dklen: Int, n: UInt64, p: UInt32, r: UInt32, salt: String) {
        self.dklen = dklen
        self.n = n
        self.p = p
        self.r = r
        self.salt = salt
    }

}
