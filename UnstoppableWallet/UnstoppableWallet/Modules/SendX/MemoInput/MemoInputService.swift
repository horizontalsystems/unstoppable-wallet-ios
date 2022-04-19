import Foundation

class MemoInputService {
    private let maxSymbols: Int
    var memo: String?

    init(maxSymbols: Int) {
        self.maxSymbols = maxSymbols
    }

}

extension MemoInputService {

    func set(text: String?) {
        if (text ?? "").isEmpty {
            memo = nil
        } else {
            memo = text
        }
    }

    func isValid(text: String) -> Bool {
        text.count <= maxSymbols
    }

}
