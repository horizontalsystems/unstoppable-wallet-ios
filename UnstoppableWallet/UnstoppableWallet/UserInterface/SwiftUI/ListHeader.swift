import SwiftUI

struct ListHeader<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: .margin12) {
            content
        }
        .padding(.horizontal, .margin16)
        .padding(.vertical, .margin10)
        .frame(maxWidth: .infinity)
        .listRowInsets(EdgeInsets())
        .background(Color.themeLawrence)
    }
}
