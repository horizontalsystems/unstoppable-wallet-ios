import SwiftUI

struct ThemeList<Content: View, Item: Hashable>: View {
    let items: [Item]
    @ViewBuilder let itemContent: (Item) -> Content

    @Environment(\.themeListStyle) var themeListStyle

    var body: some View {
        switch themeListStyle {
        case .lawrence, .bordered, .transparentInline, .borderedLawrence:
            Text("todo")
        case .transparent:
            List {
                ForEach(items, id: \.self) { item in
                    VStack(spacing: 0) {
                        if items.first == item {
                            HorizontalDivider()
                        }

                        itemContent(item)

                        HorizontalDivider()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }

                Spacer()
                    .frame(height: .margin16)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
    }
}
