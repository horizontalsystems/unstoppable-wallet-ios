import SwiftUI

struct CloudNotAvailableView: View {
    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView.instance(
            icon: .error,
            title: "backup.cloud.no_access.title".localized,
            items: [
                .warning(text: "backup.cloud.no_access.description".localized),
                .buttonGroup(.init(buttons: [
                    .init(style: .yellow, title: "button.ok".localized) {
                        isPresented = false
                    },
                ])),
            ],
            isPresented: $isPresented
        )
    }
}
