import Foundation

extension Array {

    func at(index: Int) -> Element? {
        guard self.count > index else {
            return nil
        }
        return self[index]
    }

}
