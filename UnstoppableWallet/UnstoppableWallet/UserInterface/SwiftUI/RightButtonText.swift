import SwiftUI

struct RightButtonText: View {
    let text: CustomStringConvertible
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ThemeText(text, style: .subheadSB)
                    .multilineTextAlignment(.trailing)

                Image(icon).icon(size: 20, colorStyle: .primary)
            }
        }
    }
}
