import SwiftUI

struct RightButtonText: View {
    let text: CustomStringConvertible
    var textStyle: TextStyle = .subheadSB
    let icon: String
    var iconColorStyle: ColorStyle = .primary
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ThemeText(text, style: textStyle)
                .multilineTextAlignment(.trailing)

            Image(icon).icon(size: 20, colorStyle: iconColorStyle)
        }
        .onTapGesture(perform: action)
    }
}
