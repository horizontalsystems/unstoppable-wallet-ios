import SwiftUI

struct ShortCutButtonsView<Content: View>: View {
    @ViewBuilder let content: Content

    var text: Binding<String>
    let items: [ShortCutButtonType]
    let onTap: (Int) -> ()
    let onTapDelete: () -> ()

    var body: some View {
        HStack(spacing: .margin8) {
            content

            if text.wrappedValue.isEmpty {
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
                        .buttonStyle( SecondaryCircleButtonStyle(style: .default))
                    }
                }
            } else {
                Button(action: {
                    onTapDelete()
                }, label: {
                    Image("trash_20").renderingMode(.template)
                })
                .buttonStyle(SecondaryCircleButtonStyle(style: .default))
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