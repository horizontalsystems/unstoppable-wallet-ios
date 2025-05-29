import SwiftUI

struct Informed: ViewModifier {
    let infoDescription: InfoDescription
    @State private var descriptionPresented: Bool = false

    func body(content: Content) -> some View {
        Button(action: {
            descriptionPresented = true
        }, label: {
            HStack(spacing: .margin8) {
                content
                Image("circle_information_20").themeIcon()
            }
            .padding(EdgeInsets(top: 5.5, leading: .margin16, bottom: 5.5, trailing: .margin16))
        })
        .bottomSheet(isPresented: $descriptionPresented) {
            BottomSheetView(
                icon: .info,
                title: infoDescription.title,
                items: [
                    .text(text: infoDescription.description),
                ],
                onDismiss: { descriptionPresented = false }
            )
        }
    }
}

struct InfoBottomSheet: ViewModifier {
    @Binding var info: InfoDescription?

    func body(content: Content) -> some View {
        content
            .bottomSheet(item: $info) { _info in
                BottomSheetView(
                    icon: .info,
                    title: _info.title,
                    items: [
                        .text(text: _info.description),
                    ],
                    buttons: [
                        .init(style: .yellow, title: "button.close".localized) {
                            info = nil
                        },
                    ],
                    onDismiss: { info = nil }
                )
            }
    }
}
