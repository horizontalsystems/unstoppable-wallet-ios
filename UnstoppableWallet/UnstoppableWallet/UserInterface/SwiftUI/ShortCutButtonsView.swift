import SwiftUI

struct ShortCutButtonsView<Content: View>: View {
    @ViewBuilder let content: Content

    var text: Binding<String>
    let items: [String]
    let onTap: (Int) -> ()
    let onTapDelete: () -> ()

    var body: some View {
        HStack(spacing: .margin16) {
            content

            if text.wrappedValue.isEmpty {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button(action: {
                        onTap(index)
                    }, label: {
                        Text(item).textSubhead1(color: .themeLeah)
                    })
                    .buttonStyle(SecondaryButtonStyle(style: .default))
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
