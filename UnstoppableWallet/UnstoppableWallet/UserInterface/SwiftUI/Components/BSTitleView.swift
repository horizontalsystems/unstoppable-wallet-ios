import Kingfisher
import SwiftUI

struct BSTitleView: View {
    private let showGrabber: Bool
    private let icon: Icon?
    private let title: CustomStringConvertible

    private let showDismiss: Bool
    @Binding var isPresented: Bool

    init(showGrabber: Bool = true, icon: Icon? = nil, title: CustomStringConvertible, subtitle _: CustomStringConvertible? = nil, isPresented: Binding<Bool>? = nil) {
        self.showGrabber = showGrabber
        self.icon = icon
        self.title = title

        // TODO: use if needed
        showDismiss = isPresented != nil
        _isPresented = isPresented ?? .constant(true)
    }

    var body: some View {
        VStack(spacing: 0) {
            if showGrabber {
                Rectangle()
                    .fill(Color.themeBlade)
                    .frame(width: 52, height: 4)
                    .cornerRadius(2)
                    .padding(.top, .margin8)
                    .padding(.bottom, .margin12)
            }

            if let icon {
                iconView(icon: icon)
                    .padding(.top, .margin16)
                    .padding(.bottom, .margin8)
            }

            ThemeText(title, style: .headline1)
                .padding(.top, .margin16)
                .padding(.bottom, .margin8)
        }
        .padding(.horizontal, .margin48)
    }

    @ViewBuilder private func iconView(icon: Icon) -> some View {
        switch icon {
        case let .local(name, style):
            Image(name)
                .renderingMode(.template)
                .icon(size: .iconSize72, colorStyle: style ?? .secondary)
        case let .remote(url: url, placeholder: placeholder):
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
                .frame(width: .iconSize72, height: .iconSize72)
        }
    }
}

extension BSTitleView {
    enum Icon {
        case local(name: String, style: ColorStyle?)
        case remote(url: String, placeholder: String?)

        static let warning: Self = .local(name: "warning_filled", style: .yellow)
        static let error: Self = .local(name: "warning_filled", style: .red)
        static let info: Self = .local(name: "warning_filled", style: .secondary)
        static let book: Self = .local(name: "book", style: .secondary)
        static let trash: Self = .local(name: "trash_filled", style: .red)
    }
}
