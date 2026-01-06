import Foundation
import GRDB

class SwapAsset: Codable {
    let provider: String
    let tokenQueryId: String
    let data: Data

    init(provider: String, tokenQueryId: String, data: some Encodable) throws {
        self.provider = provider
        self.tokenQueryId = tokenQueryId
        self.data = try JSONEncoder().encode(data)
    }

    func decodedData<T: Decodable>(as type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}

extension SwapAsset: FetchableRecord, PersistableRecord {
    class var databaseTableName: String {
        "SwapAsset"
    }

    enum Columns {
        static let provider = Column(CodingKeys.provider)
        static let tokenQueryId = Column(CodingKeys.tokenQueryId)
        static let data = Column(CodingKeys.data)
    }
}
