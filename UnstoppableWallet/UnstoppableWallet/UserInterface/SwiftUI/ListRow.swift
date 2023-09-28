import SwiftUI

struct ListRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: .margin16) {
            content
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        .frame(minHeight: .heightCell48)
    }
}
