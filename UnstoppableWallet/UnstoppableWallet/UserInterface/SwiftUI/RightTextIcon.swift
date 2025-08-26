import SwiftUI

struct RightTextIcon: View {
    var text: CustomStringConvertible
    var icon: String?

    var body: some View {
        HStack(spacing: .margin12) {
            ThemeText(text, style: .subheadSB)
                .multilineTextAlignment(.trailing)

            if let icon {
                Image(icon).icon(size: .iconSize20)
            }
        }
    }
}
