import SwiftUI

struct RightButtonText: View {
    let text: CustomStringConvertible
    var textStyle: TextStyle = .subheadSB
    let icon: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ThemeText(text, style: textStyle)
                .multilineTextAlignment(.trailing)

            Image(icon).icon(size: 20, colorStyle: .primary)
        }
        .onTapGesture(perform: action)
    }
}
