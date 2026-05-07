import SwiftUI

struct Informed: ViewModifier {
    let infoDescription: InfoDescription
    var horizontalPadding: CGFloat = 16

    func body(content: Content) -> some View {
        HStack(spacing: 8) {
            content
            ThemeImage("info_filled", size: 20)
        }
        .padding(.horizontal, horizontalPadding)
        .onTapGesture {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BottomSheetView(
                    items: [
                        .title(icon: ThemeImage.book, title: infoDescription.title),
                        .text(text: infoDescription.description),
                        .buttonGroup(.init(buttons: [
                            .init(style: .gray, title: "button.understood".localized) {
                                isPresented.wrappedValue = false
                            },
                        ])),
                    ],
                )
            }
        }
    }
}
