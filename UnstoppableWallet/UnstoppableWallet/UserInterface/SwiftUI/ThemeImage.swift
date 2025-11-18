import Kingfisher
import SwiftUI

struct ThemeImage: View {
    private let image: ImageType
    private let size: CGFloat
    private let colorStyle: ColorStyle

    init(_ name: CustomStringConvertible, size: CGFloat? = nil, colorStyle: ColorStyle? = nil) {
        if let componentImage = name as? ComponentImage {
            switch componentImage {
            case let .local(name, localSize, localColorStyle):
                image = .local(name: name)
                self.size = localSize ?? size ?? .iconSize24
                self.colorStyle = localColorStyle ?? colorStyle ?? .secondary
            case let .remote(url, placeholder, localSize):
                image = .remote(url: url, placeholder: placeholder)
                self.size = localSize ?? size ?? .iconSize24
                self.colorStyle = .primary
            }
        } else {
            image = .local(name: name.description)
            self.size = size ?? .iconSize24
            self.colorStyle = colorStyle ?? .secondary
        }
    }

    var body: some View {
        switch image {
        case let .local(name):
            Image(name)
                .renderingMode(.template)
                .icon(size: size, colorStyle: colorStyle)
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
                .frame(width: size, height: size)
        }
    }
}

extension ThemeImage {
    enum ImageType {
        case local(name: String)
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
}
