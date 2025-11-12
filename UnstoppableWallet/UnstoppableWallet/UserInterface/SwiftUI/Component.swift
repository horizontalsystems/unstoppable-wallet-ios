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

enum ComponentImage: CustomStringConvertible {
    case local(name: String, size: CGFloat?, colorStyle: ColorStyle?)
    case remote(url: String, placeholder: String?, size: CGFloat?)

    init(_ name: String, size: CGFloat? = nil, colorStyle: ColorStyle? = nil) {
        self = .local(name: name, size: size, colorStyle: colorStyle)
    }

    init(url: String, placeholder: String? = nil, size: CGFloat? = nil) {
        self = .remote(url: url, placeholder: placeholder, size: size)
    }

    var description: String {
        switch self {
        case let .local(name, _, _): return name
        case let .remote(url, _, _): return url
        }
    }
}
