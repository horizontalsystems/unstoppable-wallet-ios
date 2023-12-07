import SwiftUI

struct ListSectionHeader: View {
    private let text: String
    private let color: Color

    init(text: String, color: Color = .themeGray) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .themeSubhead1(color: color)
            .frame(height: .margin32)
            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))
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
