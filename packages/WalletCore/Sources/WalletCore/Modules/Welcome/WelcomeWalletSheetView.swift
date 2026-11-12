import SwiftUI

struct WelcomeWalletSheetView: View {
    let title: String
    let groups: [[WelcomeViewModel.Option]]
    @Binding var isPresented: Bool
    let onSelect: (WelcomeViewModel.Option) -> Void

    var body: some View {
        BottomSheetView(items: items)
    }

    private var items: [BSModule.Item] {
        // `.customList` adds `.margin8` above itself: 8 + 16 = 24 below the title row, 8 + 8 = 16 between groups.
        var items: [BSModule.Item] = [
            .title(title: title, isPresented: $isPresented),
            spacer(height: .margin16),
        ]

        for (index, group) in groups.enumerated() {
            if index > 0 {
                items.append(spacer(height: .margin8))
            }

            items.append(.customList(views: rows(options: group)))
        }

        items.append(spacer(height: .margin64))

        return items
    }

    private func spacer(height: CGFloat) -> BSModule.Item {
        .custom(view: AnyView(Color.clear.frame(height: height)))
    }

    private func rows(options: [WelcomeViewModel.Option]) -> [AnyView] {
        var views = [AnyView]()

        for (index, option) in options.enumerated() {
            if index > 0 {
                views.append(AnyView(HorizontalDivider()))
            }

            views.append(AnyView(row(option: option)))
        }

        return views
    }

    private func row(option: WelcomeViewModel.Option) -> some View {
        Cell(
            left: {
                ThemeImage(option.icon, size: .iconSize32, colorStyle: .brand)
            },
            middle: {
                MultiText(title: option.title, subtitle: option.description)
            },
            right: {
                Image.disclosureIcon
            },
            action: {
                onSelect(option)
            }
        )
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }
}
