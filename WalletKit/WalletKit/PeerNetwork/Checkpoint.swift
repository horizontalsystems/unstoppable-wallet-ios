import Foundation

struct Checkpoint {
    let height: Int
    let hash: Data
    let timestamp: Int
    let target: Int

    init?(height: Int, reversedHex: String, timestamp: Int, target: Int) {
        guard let reversedData = Data(hex: reversedHex) else {
            return nil
        }

        self.height = height
        self.hash = Data(reversedData.reversed())
        self.timestamp = timestamp
        self.target = target
    }

}
