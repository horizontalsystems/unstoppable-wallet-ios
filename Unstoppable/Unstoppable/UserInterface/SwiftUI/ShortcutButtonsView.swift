import SwiftUI

struct ShortcutButtonsView<Content: View>: View {
    @ViewBuilder let content: Content

    @Binding var showDelete: Bool
    let items: [ShortCutButtonType]
    let onTap: (Int) -> Void
    let onTapDelete: () -> Void

    var body: some View {
        HStack(spacing: .margin8) {
            content

            if showDelete {
                IconButton(icon: "trash", style: .secondary, size: .small) {
                    onTapDelete()
                }
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    switch item {
                    case let .text(title):
                        ThemeButton(text: title, style: .secondary, size: .small) {
                            onTap(index)
                        }
                    case let .icon(name):
                        IconButton(icon: name, style: .secondary, size: .small) {
                            onTap(index)
                        }
                    }
                }
            }
        }
    }
}

enum ShortCutButtonType {
    case text(String)
    case icon(String)

    var isImage: Bool {
        switch self {
        case .icon: return true
        case .text: return false
        }
    }
}
