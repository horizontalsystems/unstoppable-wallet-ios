import Foundation
import RxSwift

protocol IRandomProvider {
    func getRandomIndexes(count: Int) -> [Int]
}
