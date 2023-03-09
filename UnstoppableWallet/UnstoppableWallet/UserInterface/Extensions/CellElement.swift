import UIKit
import ComponentKit

extension CellBuilderNew.CellElement {  // prepared cell elements for most frequency used layouts

    static func textElement(text: Text?, parameters: TextParameters = .none) -> CellBuilderNew.CellElement {
        .text { component in
            if let text = text {
                component.isHidden = false

                component.font = text.font
                component.textColor = text.textColor
                component.text = text.text

                if parameters.contains(.highHugging) {
                    component.setContentHuggingPriority(.required, for: .horizontal)
                }
                if parameters.contains(.highResistance) {
                    component.setContentCompressionResistancePriority(.required, for: .horizontal)
                }
                if parameters.contains(.rightAlignment) {
                    component.textAlignment = .right
                }
                if parameters.contains(.centerAlignment) {
                    component.textAlignment = .center
                }
                if parameters.contains(.truncatingMiddle) {
                    component.lineBreakMode = .byTruncatingMiddle
                }
                if parameters.contains(.multiline) {
                    component.numberOfLines = 0
                }
            } else {
                component.isHidden = true
            }
        }
    }

    static func imageElement(image: Image?, size: ImageSize) -> CellBuilderNew.CellElement {
        let block: (ImageComponent) -> () = { component in
            if let image = image {
                component.isHidden = false
                if let image = image.image { // setup local image
                    component.imageView.image = image
                } else if let url = image.url { // setup global url with placeholder
                    component.imageView.setImage(withUrlString: url, placeholder: image.placeholder.flatMap {
                        UIImage(named: $0)
                    })
                } else {
                    component.isHidden = true
                }
            } else {
                component.isHidden = true
            }
        }
        switch size {
        case .image16: return .image16(block)
        case .image20: return .image20(block)
        case .image24: return .image24(block)
        case .image32: return .image32(block)
        }
    }

    static func accessoryElements(_ type: AccessoryType) -> [CellBuilderNew.CellElement] {
        var elements = [CellBuilderNew.CellElement]()
        switch type {
        case let accessoryType as ImageAccessoryType:
            if let image = accessoryType.image {
                elements.append(.margin8)
                elements.append(.image20 { (component: ImageComponent) -> () in
                    component.imageView.image = image
                    component.isHidden = !accessoryType.visible
                })
            }
        case let accessoryType as SwitchAccessoryType:
            elements.append(.switch { (component: SwitchComponent) -> () in
                component.switchView.setOn(accessoryType.isOn, animated: accessoryType.animated)
                component.onSwitch = accessoryType.onSwitch
            })
        default: ()
        }
        return elements
    }

}

extension CellBuilderNew.CellElement {

    struct Image {
        static func local(_ image: UIImage?) -> Self { Image(image: image, url: nil, placeholder: nil) }
        static func url(_ url: String?, placeholder: String? = nil) -> Self { Image(image: nil, url: url, placeholder: placeholder) }

        let image: UIImage?
        let url: String?
        let placeholder: String?
    }

    enum ImageSize {
        case image16
        case image20
        case image24
        case image32
    }

    struct Text {
        static func body(_ text: String?, color: UIColor = .themeLeah) -> Self { Text(text: text, font: .body, textColor: color) }
        static func subhead1(_ text: String?, color: UIColor = .themeLeah) -> Self { Text(text: text, font: .subhead1, textColor: color) }
        static func subhead2(_ text: String?, color: UIColor = .themeGray) -> Self { Text(text: text, font: .subhead2, textColor: color) }
        static func caption(_ text: String?, color: UIColor = .themeGray) -> Self { Text(text: text, font: .caption, textColor: color) }
        static func custom(_ text: String?, _ font: UIFont, _ color: UIColor) -> Self { Text(text: text, font: font, textColor: color) }

        let text: String?
        let font: UIFont
        let textColor: UIColor
    }

    struct TextParameters: OptionSet {
        static let none = TextParameters([])
        static let allCompression = TextParameters([.highResistance, .highHugging])

        let rawValue: UInt8

        static let highResistance = TextParameters(rawValue: 1 << 0)
        static let highHugging = TextParameters(rawValue: 1 << 1)
        static let truncatingMiddle = TextParameters(rawValue: 1 << 2)
        static let rightAlignment = TextParameters(rawValue: 1 << 3)
        static let centerAlignment = TextParameters(rawValue: 1 << 4)
        static let multiline = TextParameters(rawValue: 1 << 5)
    }

    class AccessoryType {
        static let none = AccessoryType()
        static let disclosure: AccessoryType = ImageAccessoryType(image: UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray))
        static let dropdown: AccessoryType = ImageAccessoryType(image: UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray))
        static func check(_ visible: Bool = true) -> AccessoryType { ImageAccessoryType(image: UIImage(named: "check_1_20")?.withTintColor(.themeJacob), visible: visible) }
        static func `switch`(isOn: Bool = false, animated: Bool = false, onSwitch: ((Bool) -> ())?) -> AccessoryType { SwitchAccessoryType(isOn: isOn, animated: animated, onSwitch: onSwitch) }
    }

    class ImageAccessoryType: AccessoryType {
        let image: UIImage?
        let visible: Bool

        init(image: UIImage?, visible: Bool = true) {
            self.image = image
            self.visible = visible

            super.init()
        }
    }

    class SwitchAccessoryType: AccessoryType {
        let isOn: Bool
        let animated: Bool
        let onSwitch: ((Bool) -> ())?

        init(isOn: Bool = false, animated: Bool, onSwitch: ((Bool) -> ())?) {
            self.isOn = isOn
            self.animated = animated
            self.onSwitch = onSwitch

            super.init()
        }
    }

}
