import SwiftUI

extension Image {
    // deprecated!
    func themeIcon(color: Color = .themeGray) -> some View {
        renderingMode(.template).foregroundColor(color)
    }

    func icon(size: CGFloat = .iconSize24, colorStyle: ColorStyle = .secondary) -> some View {
        resizable()
            .foregroundColor(colorStyle.color)
            .frame(size: size)
    }

    func icon(size: CGSize, colorStyle: ColorStyle = .secondary) -> some View {
        resizable()
            .foregroundColor(colorStyle.color)
            .frame(width: size.width, height: size.height)
    }

    func buttonIcon(size: CGFloat = .iconSize24) -> some View {
        resizable()
            .frame(size: size)
    }

    static var disclosureIcon: some View {
        Image("arrow_b_right").icon(size: CGFloat.iconSize20)
    }

    static func disclosure(colorStyle: ColorStyle) -> some View {
        Image("arrow_b_right").icon(size: .iconSize20, colorStyle: colorStyle)
    }

    static func dropdown(colorStyle: ColorStyle) -> some View {
        Image("arrow_s_down").icon(size: .iconSize20, colorStyle: colorStyle)
    }

    static var checkIcon: some View {
        Image("check_1_20").themeIcon(color: .themeJacob)
    }

    static var warningIcon: some View {
        Image("warning_2_20").themeIcon(color: .themeLucian)
    }

    static func checkbox(active: Bool, size: CGFloat = .margin24) -> some View {
        ThemeImage(
            active ?
                ComponentImage(image: "checkbox_active", size: CGSize(width: size, height: size)) :
                "checkbox_diactive",
            size: size
        )
    }
}
