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
                Button(action: {
                    onTapDelete()
                }, label: {
                    Image("trash_20").renderingMode(.template)
                })
                .buttonStyle(SecondaryCircleButtonStyle(style: .default))
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    switch item {
                    case let .text(title):
                        Button(action: {
                            onTap(index)
                        }, label: {
                            Text(title).textSubhead1(color: .themeLeah)
                        })
                        .buttonStyle(SecondaryButtonStyle(style: .default))
                    case let .icon(name):
                        Button(action: {
                            onTap(index)
                        }, label: {
                            Image(name).renderingMode(.template)
                        })
                        .buttonStyle(SecondaryCircleButtonStyle(style: .default))
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
