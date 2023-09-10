import SwiftUI

extension Image {
    func themeIcon(color: Color = .themeGray) -> some View {
        renderingMode(.template).foregroundColor(color)
    }

    static var disclosureIcon: some View {
        Image("arrow_big_forward_20").themeIcon()
    }

    static var checkIcon: some View {
        Image("check_1_20").themeIcon(color: .themeJacob)
    }
}
