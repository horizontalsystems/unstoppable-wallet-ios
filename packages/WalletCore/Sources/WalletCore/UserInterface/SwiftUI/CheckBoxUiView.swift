import SwiftUI

struct CheckBoxUiView: View {
    private let size: CGFloat = 24

    @Binding var checked: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(checked ? Color.themeYellow : Color.themeBlade)
                .frame(width: size, height: size)

            Image("check_2_24")
                .themeIcon(color: .themeDark)
                .opacity(checked ? 1 : 0)
        }
    }
}
