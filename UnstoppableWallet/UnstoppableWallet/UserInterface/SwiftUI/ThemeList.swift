import SwiftUI

struct ThemeList<Content: View, Item: Hashable>: View {
    private let items: [Item]
    private let onMove: ((IndexSet, Int) -> Void)?
    private let itemContent: (Item) -> Content

    @Environment(\.themeListStyle) var themeListStyle

    init(items: [Item], onMove: ((IndexSet, Int) -> Void)? = nil, @ViewBuilder itemContent: @escaping (Item) -> Content) {
        self.items = items
        self.onMove = onMove
        self.itemContent = itemContent
    }

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
                .onMove(perform: onMove)

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

struct ThemeLazyList<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @Environment(\.themeListStyle) var themeListStyle

    var body: some View {
        switch themeListStyle {
        case .lawrence, .bordered, .transparentInline, .borderedLawrence:
            Text("todo")
        case .transparent:
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    content()

                    Spacer().frame(height: .margin32)
                }
            }
        }
    }
}

struct ThemeLazyListSection<Content: View, Item: Hashable>: View {
    let header: String
    let items: [Item]
    @ViewBuilder let itemContent: (Item) -> Content

    @Environment(\.themeListStyle) var themeListStyle

    var body: some View {
        switch themeListStyle {
        case .lawrence, .bordered, .transparentInline, .borderedLawrence:
            Text("todo")
        case .transparent:
            Section {
                ForEach(items, id: \.self) { item in
                    VStack(spacing: 0) {
                        if items.first == item {
                            HorizontalDivider()
                        }

                        itemContent(item)

                        HorizontalDivider()
                    }
                }
            } header: {
                Text(header)
                    .themeSubhead1(alignment: .leading)
                    .textCase(.uppercase)
                    .padding(.horizontal, .margin16)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(Color.themeTyler)
            }
        }
    }
}
