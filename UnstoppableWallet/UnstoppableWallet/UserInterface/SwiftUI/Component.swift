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
    case icon(name: String, size: CGSize?, colorStyle: ColorStyle?)
    case image(name: String, contentMode: ContentMode, size: CGSize?)
    case remote(url: String, placeholder: String?, size: CGSize?)

    init(_ name: String, colorStyle: ColorStyle? = nil) {
        self = .icon(name: name, size: nil, colorStyle: colorStyle)
    }

    init(_ name: String, size: CGFloat, colorStyle: ColorStyle? = nil) {
        self = .icon(name: name, size: CGSize(width: size, height: size), colorStyle: colorStyle)
    }

    init(_ name: String, size: CGSize, colorStyle: ColorStyle? = nil) {
        self = .icon(name: name, size: size, colorStyle: colorStyle)
    }

    init(image: String, contentMode: ContentMode = .fill, size: CGSize? = nil) {
        self = .image(name: image, contentMode: contentMode, size: size)
    }

    init(url: String, placeholder: String? = nil, size: CGSize? = nil) {
        self = .remote(url: url, placeholder: placeholder, size: size)
    }

    var description: String {
        switch self {
        case let .icon(name, _, _): return name
        case let .image(name, _, _): return name
        case let .remote(url, _, _): return url
        }
    }
}

extension CustomStringConvertible {
    func styled(_ colorStyle: ColorStyle, forced: Bool = false) -> CustomStringConvertible {
        switch self {
        case let component as ComponentText:
            if component.colorStyle == nil || forced {
                return ComponentText(text: component.text, colorStyle: colorStyle, dimmed: component.dimmed)
            }
        case let component as String:
            return ComponentText(text: component, colorStyle: colorStyle)

        case let component as ComponentBadge:
            if component.colorStyle == nil || forced {
                return ComponentBadge(text: component.text, change: component.change, mode: component.mode, colorStyle: colorStyle)
            }

        case let .icon(name, size, style) as ComponentImage:
            if style == nil || forced {
                return ComponentImage.icon(name: name, size: size, colorStyle: colorStyle)
            }

        default: return self
        }

        return self
    }
}
