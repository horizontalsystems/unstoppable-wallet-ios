import SwiftUI

struct ListSectionHeader: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
                .themeSubhead1()
                .frame(height: .margin32)
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))
    }

}
