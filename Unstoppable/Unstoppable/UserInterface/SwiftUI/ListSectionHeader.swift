import SwiftUI

struct ListSectionHeader: View {
    private let text: String
    private let uppercased: Bool
    private let color: ColorStyle
    private let insets: EdgeInsets

    init(text: String, uppercased: Bool = true, color: ColorStyle = .secondary, insets: EdgeInsets = .padding16) {
        self.text = text
        self.uppercased = uppercased
        self.color = color
        self.insets = insets
    }

    var body: some View {
        HStack {
            ThemeText(uppercased ? text.uppercased() : text, style: .subheadSB, colorStyle: color)
                .padding(.bottom, .margin12)

            Spacer()
        }
        .padding(insets)
    }
}

struct ListSectionHeader2: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .themeSubhead1()
            .frame(height: .heightSingleLineCell)
    }
}
