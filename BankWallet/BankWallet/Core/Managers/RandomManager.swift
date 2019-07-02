import Foundation
import Darwin

class RandomManager: IRandomManager {

    func getRandomIndexes(max: Int, count: Int) -> [Int] {
        var indexes = [Int]()

        while indexes.count < count {
            let index = Int(arc4random_uniform(UInt32(max)) + 1)
            if !indexes.contains(index) {
                indexes.append(index)
            }
        }

        return indexes
    }

}
