import SwiftUI

struct ComponentText: CustomStringConvertible {
    let text: String
    var colorStyle: ColorStyle?
    var dimmed: Bool = false

    var description: String { text }
}

struct ComponentBadge: CustomStringConvertible {
    let text: String
    var change: Int?
    var mode: BadgeViewNew.Mode?
    var colorStyle: ColorStyle?

    var description: String { text }
}

extension Text {
    init(componentText: ComponentText) {
        self.init(componentText.text)
    }
}
