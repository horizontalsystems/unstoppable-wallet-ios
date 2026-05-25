import Foundation

public struct LastBlockInfo {
    public let height: Int
    public let timestamp: Int?

    public init(height: Int, timestamp: Int?) {
        self.height = height
        self.timestamp = timestamp
    }
}
