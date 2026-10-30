import Foundation

struct CaretText: Equatable {
    var text: String = ""
    var caretOffset: Int = 0 // UTF-16 offset, same unit as NSRange

    static func end(_ text: String) -> CaretText {
        CaretText(text: text, caretOffset: (text as NSString).length)
    }
}
