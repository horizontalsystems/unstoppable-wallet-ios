import SwiftUI

struct CheckBoxUiView: View {
    private let size: CGFloat = .iconSize24

    @Binding var checked: Bool

    var body: some View {
        ZStack {
            if checked {
                ThemeImage("done_e_filled_full", size: size, colorStyle: .yellow)
            } else {
                Circle()
                    .stroke(Color.themeAndy, lineWidth: 1)
                    .frame(width: size, height: size)
            }
        }
    }
}
