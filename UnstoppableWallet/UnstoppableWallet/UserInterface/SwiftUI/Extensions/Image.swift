import SwiftUI

extension Image {
    func themeIcon(color: Color = .themeGray) -> some View {
        renderingMode(.template).foregroundColor(color)
    }

    func icon(size: CGFloat = .iconSize24, colorStyle: ColorStyle = .secondary) -> some View {
        resizable()
            .foregroundColor(colorStyle.color)
            .frame(size: size)
    }

    func buttonIcon(size: CGFloat = .iconSize24) -> some View {
        resizable()
            .frame(size: size)
    }

    static var disclosureIcon: some View {
        Image("arrow_big_forward_20").themeIcon()
    }

    static var checkIcon: some View {
        Image("check_1_20").themeIcon(color: .themeJacob)
    }

    static var warningIcon: some View {
        Image("warning_2_20").themeIcon(color: .themeLucian)
    }
}
