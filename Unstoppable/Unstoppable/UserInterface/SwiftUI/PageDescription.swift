import SwiftUI

struct PageDescription: View {
    let text: String

    var body: some View {
        Text(text)
            .themeSubhead2()
            .padding(EdgeInsets(top: .margin12, leading: .margin32, bottom: .margin32, trailing: .margin32))
    }
}
