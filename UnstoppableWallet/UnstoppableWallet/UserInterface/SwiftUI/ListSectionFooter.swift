import SwiftUI

struct ListSectionFooter: View {
    let text: String

    var body: some View {
        Text(text)
                .themeSubhead2()
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: 0, trailing: .margin16))
    }

}
