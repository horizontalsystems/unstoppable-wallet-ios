import SwiftUI

struct ComponentText: CustomStringConvertible {
    let text: String
    var colorStyle: TextColorStyle?
    var dimmed: Bool = false

    var description: String { text }
}

struct ComponentBadge: CustomStringConvertible {
    let text: String
    var change: Int?

    var description: String { text }
}

extension Text {
    init(componentText: ComponentText) {
        self.init(componentText.text)
    }
}

extension BadgeViewNew {
    init(_ text: CustomStringConvertible, style: Style = .small, change: Int? = nil) {
        if let componentBadge = text as? ComponentBadge {
            self.init(style: style, text: componentBadge.text, change: change ?? componentBadge.change)
        } else {
            self.init(style: style, text: text.description, change: change)
        }
    }
}
