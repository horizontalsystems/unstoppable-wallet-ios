import SwiftUI

struct ListHeader<Content: View>: View {
    var scrollable: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        Group {
            if scrollable {
                ScrollView(.horizontal, showsIndicators: false) {
                    stack()
                }
            } else {
                stack()
            }
        }
        .frame(maxWidth: .infinity)
        .listRowInsets(EdgeInsets())
        .background(Color.themeLawrence)
    }

    @ViewBuilder func stack() -> some View {
        HStack(spacing: .margin12) {
            content
        }
        .padding(.horizontal, .margin16)
        .padding(.vertical, .margin10)
    }
}
