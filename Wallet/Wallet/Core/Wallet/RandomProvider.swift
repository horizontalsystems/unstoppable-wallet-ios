import Foundation
import Darwin

class RandomProvider: IRandomProvider {

    func getRandomIndexes(count: Int) -> [Int] {
        var indexes = [Int]()

        while indexes.count < count {
            let index = Int(arc4random_uniform(12) + 1)
            if !indexes.contains(index) {
                indexes.append(index)
            }
        }

        return indexes
    }

}
