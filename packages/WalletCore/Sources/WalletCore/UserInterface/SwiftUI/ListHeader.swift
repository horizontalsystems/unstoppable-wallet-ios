import SwiftUI

public struct ListHeader<Content: View>: View {
    var scrollable: Bool = false
    @ViewBuilder let content: Content

    public init(scrollable: Bool = false, @ViewBuilder content: () -> Content) {
        self.scrollable = scrollable
        self.content = content()
    }

    public var body: some View {
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
