import SwiftUI

public struct ShortcutButtonsView: View {
    @Binding var showDelete: Bool
    let items: [ShortCutButtonType]
    let onTap: (Int) -> Void
    let onTapDelete: () -> Void

    public init(
        showDelete: Binding<Bool>,
        items: [ShortCutButtonType],
        onTap: @escaping (Int) -> Void,
        onTapDelete: @escaping () -> Void
    ) {
        _showDelete = showDelete
        self.items = items
        self.onTap = onTap
        self.onTapDelete = onTapDelete
    }

    public var body: some View {
        HStack(spacing: .margin8) {
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

public enum ShortCutButtonType {
    case text(String)
    case icon(String)

    var isImage: Bool {
        switch self {
        case .icon: return true
        case .text: return false
        }
    }
}
