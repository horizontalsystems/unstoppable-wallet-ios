import SwiftUI

struct MiddleTextIcon: View {
    var text: CustomStringConvertible
    var icon: String?

    var body: some View {
        HStack(spacing: .margin8) {
            ThemeText(text, style: .subhead)
                .multilineTextAlignment(.leading)

            if let icon {
                Image(icon).icon(size: .iconSize20)
            }
        }
    }
}
