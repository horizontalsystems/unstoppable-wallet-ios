import SwiftUI

struct ComponentText: CustomStringConvertible {
    let text: String
    var color: Color?

    var description: String { text }
}

struct AttributedComponentText: CustomStringConvertible {
    let text: AttributedString

    var description: String { text.description }
}

extension Text {
    init(componentText: ComponentText) {
        self.init(componentText.text)
    }
}

struct ComponentBadge: CustomStringConvertible {
    let text: String
    var change: Int?
    var mode: BadgeView.Mode?
    var color: Color?
    var onTap: (() -> Void)?

    init(text: String, change: Int? = nil, mode: BadgeView.Mode? = nil, color: Color? = nil, onTap: (() -> Void)? = nil) {
        self.text = text
        self.change = change
        self.mode = mode
        self.color = color
        self.onTap = onTap
    }

    var description: String { text }
}

enum ComponentImage: CustomStringConvertible {
    case icon(name: String, size: CGSize?, color: Color?)
    case image(name: String, contentMode: ContentMode, size: CGSize?)
    case remote(url: String, placeholder: String?, size: CGSize?)

    init(_ name: String, color: Color? = nil) {
        self = .icon(name: name, size: nil, color: color)
    }

    init(_ name: String, size: CGFloat, color: Color? = nil) {
        self = .icon(name: name, size: CGSize(width: size, height: size), color: color)
    }

    init(_ name: String, size: CGSize, color: Color? = nil) {
        self = .icon(name: name, size: size, color: color)
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
    func styled(_ color: Color, forced: Bool = false) -> CustomStringConvertible {
        switch self {
        case let component as ComponentText:
            if component.color == nil || forced {
                return ComponentText(text: component.text, color: color)
            }

        case let component as String:
            return ComponentText(text: component, color: color)

        case let component as ComponentBadge:
            if component.color == nil || forced {
                return ComponentBadge(text: component.text, change: component.change, mode: component.mode, color: color)
            }

        case let .icon(name, size, style) as ComponentImage:
            if style == nil || forced {
                return ComponentImage.icon(name: name, size: size, color: color)
            }

        default: return self
        }

        return self
    }
}
