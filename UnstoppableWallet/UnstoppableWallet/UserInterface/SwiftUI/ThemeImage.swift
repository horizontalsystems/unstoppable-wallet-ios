import Kingfisher
import SwiftUI

struct ThemeImage: View {
    private let image: ImageType
    private let size: CGSize?
    private let colorStyle: ColorStyle

    init(_ name: CustomStringConvertible, size: CGFloat? = nil, colorStyle: ColorStyle? = nil) {
        self.init(name, size: size.map { CGSize(width: $0, height: $0) }, colorStyle: colorStyle)
    }

    init(_ name: CustomStringConvertible, size: CGSize? = nil, colorStyle: ColorStyle? = nil) {
        if let componentImage = name as? ComponentImage {
            switch componentImage {
            case let .icon(name, localSize, localColorStyle):
                image = .icon(name: name)
                self.size = localSize ?? size
                self.colorStyle = localColorStyle ?? colorStyle ?? .secondary
            case let .image(name, contentMode, localSize):
                image = .image(name: name, contentMode: contentMode)
                self.size = localSize ?? size
                self.colorStyle = .primary
            case let .remote(url, placeholder, localSize):
                image = .remote(url: url, placeholder: placeholder)
                self.size = localSize ?? size
                self.colorStyle = .primary
            }
        } else {
            image = .icon(name: name.description)
            self.size = size ?? .size24
            self.colorStyle = colorStyle ?? .secondary
        }
    }

    var body: some View {
        switch image {
        case let .icon(name):
            Image(name)
                .renderingMode(.template)
                .icon(size: size ?? .size24, colorStyle: colorStyle)
        case let .image(name: name, contentMode: contentMode):
            if let size {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .applyFrame(size: size)
            } else {
                Image(name)
            }
        case let .remote(url, placeholder):
            KFImage.url(URL(string: url))
                .resizable()
                .placeholder {
                    if let placeholder {
                        Image(placeholder)
                    } else {
                        RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                            .fill(Color.themeBlade)
                    }
                }
                .applyFrame(size: size)
        }
    }
}

extension ThemeImage {
    enum ImageType {
        case icon(name: String)
        case image(name: String, contentMode: SwiftUICore.ContentMode)
        case remote(url: String, placeholder: String?)
    }
}

extension ThemeImage {
    static let warning = ComponentImage("warning_filled", size: .iconSize72, colorStyle: .yellow)
    static let error = ComponentImage("warning_filled", size: .iconSize72, colorStyle: .red)
    static let info = ComponentImage("warning_filled", size: .iconSize72)
    static let book = ComponentImage("book", size: .iconSize72)
    static let trash = ComponentImage("trash_filled", size: .iconSize72, colorStyle: .red)
    static let shieldOff = ComponentImage("shield_off", size: .iconSize72)
    static let cloud = ComponentImage("cloud", size: .iconSize72)
}
