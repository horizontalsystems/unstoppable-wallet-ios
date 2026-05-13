import Kingfisher
import SwiftUI

struct ThemeImage: View {
    private static let defaultSize = CGSize(width: 24, height: 24)

    private let image: ImageType
    private let size: CGSize?
    private let color: Color

    init(_ name: CustomStringConvertible, size: CGFloat? = nil, color: Color? = nil) {
        self.init(name, size: size.map { CGSize(width: $0, height: $0) }, color: color)
    }

    init(_ name: CustomStringConvertible, size: CGSize? = nil, color: Color? = nil) {
        if let componentImage = name as? ComponentImage {
            switch componentImage {
            case let .icon(name, localSize, localColor):
                image = .icon(name: name)
                self.size = localSize ?? size
                self.color = localColor ?? color ?? .themeGray
            case let .image(name, contentMode, localSize):
                image = .image(name: name, contentMode: contentMode)
                self.size = localSize ?? size
                self.color = .themeLeah
            case let .remote(url, placeholder, localSize):
                image = .remote(url: url, placeholder: placeholder)
                self.size = localSize ?? size
                self.color = .themeLeah
            }
        } else {
            image = .icon(name: name.description)
            self.size = size
            self.color = color ?? .themeGray
        }
    }

    var body: some View {
        switch image {
        case let .icon(name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .foregroundColor(color)
                .applyFrame(size: size ?? Self.defaultSize)
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
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
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
