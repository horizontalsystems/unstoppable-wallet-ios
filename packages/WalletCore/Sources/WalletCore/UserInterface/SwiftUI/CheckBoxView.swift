import SwiftUI

struct CheckBoxView: View {
    let checked: Bool

    var body: some View {
        ZStack {
            if checked {
                ThemeImage("done_e_filled_full", size: .iconSize24, colorStyle: .brand)
            } else {
                Circle()
                    .stroke(Color.themeAndy, lineWidth: 1)
                    .frame(size: .iconSize24)
            }
        }
    }
}
