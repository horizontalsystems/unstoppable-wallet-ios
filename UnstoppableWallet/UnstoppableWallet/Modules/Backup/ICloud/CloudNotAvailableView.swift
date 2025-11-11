import SwiftUI

struct CloudNotAvailableView: View {
    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView(
            items: [
                .title(icon: ThemeImage.error, title: "backup.cloud.no_access.title".localized),
                .warning(text: "backup.cloud.no_access.description".localized),
                .buttonGroup(.init(buttons: [
                    .init(style: .yellow, title: "button.ok".localized) {
                        isPresented = false
                    },
                ])),
            ],
        )
    }
}
