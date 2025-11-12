import SwiftUI

struct RightTextIcon: View {
    var text: CustomStringConvertible
    var icon: CustomStringConvertible?

    var body: some View {
        HStack(spacing: .margin12) {
            ThemeText(text, style: .subheadSB)
                .multilineTextAlignment(.trailing)

            if let icon {
                ThemeImage(icon, size: .iconSize20)
            }
        }
    }
}
