import Foundation

public struct CautionNew: Equatable, Hashable {
    public let title: String?
    public let text: String
    public let type: CautionType

    public init(title: String? = nil, text: String, type: CautionType) {
        self.title = title
        self.text = text
        self.type = type
    }
}
