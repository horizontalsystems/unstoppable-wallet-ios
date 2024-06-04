import SwiftUI
import UIKit

let themeListTopViewId = "theme_list_top_view_id"

struct ThemeList<Content: View>: View {
    private let content: () -> Content
    private let bottomSpacing: CGFloat?
    private let invisibleTopView: Bool

    init(bottomSpacing: CGFloat? = nil, invisibleTopView: Bool = false, @ViewBuilder _ content: @escaping () -> Content) {
        self.bottomSpacing = bottomSpacing
        self.invisibleTopView = invisibleTopView
        self.content = content
    }

    init<Item: Hashable, ItemContent: View>(
        _ items: [Item],
        bottomSpacing: CGFloat? = nil,
        invisibleTopView: Bool = false,
        onMove: ((IndexSet, Int) -> Void)? = nil,
        @ViewBuilder itemContent: @escaping (Item) -> ItemContent
    ) where Content == ListForEach<ItemContent, Item> {
        self.bottomSpacing = bottomSpacing
        self.invisibleTopView = invisibleTopView

        content = {
            ListForEach(items, onMove: onMove, itemContent: itemContent)
        }
    }

    var body: some View {
        List {
            if invisibleTopView {
                Color.clear
                    .id(themeListTopViewId)
                    .frame(height: 0)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }

            content()

            if let bottomSpacing {
                Spacer()
                    .frame(height: bottomSpacing)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
        .themeListStyle(.transparent)
    }
}

struct ThemeListSectionHeader: View {
    let text: String

    var body: some View {
        Text(text)
            .themeSubhead1(alignment: .leading)
            .textCase(.uppercase)
            .padding(.horizontal, .margin16)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .background(Color.themeTyler)
    }
}

struct ListForEach<Content: View, Item: Hashable>: View {
    private let items: [Item]
    private let onMove: ((IndexSet, Int) -> Void)?
    private let itemContent: (Item) -> Content

    init(_ items: [Item], onMove: ((IndexSet, Int) -> Void)? = nil, @ViewBuilder itemContent: @escaping (Item) -> Content) {
        self.items = items
        self.onMove = onMove
        self.itemContent = itemContent
    }

    var body: some View {
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
    }
}
