import SwiftUI

struct CopyConfirmationWrapperView: View {
    let value: String
    let onCopy: (() -> Void)?
    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView(
            items: [
                .title(icon: ThemeImage.error, title: "copy_warning.title".localized),
                .text(text: "copy_warning.description".localized),
                .buttonGroup(
                    .init(buttons: [
                        .init(
                            style: .secondary,
                            title: "copy_warning.i_will_risk_it".localized,
                            action: {
                                UIPasteboard.general.string = value
                                HudHelper.instance.show(banner: .copied)
                                onCopy?()
                                isPresented = false
                            }
                        ),
                        .init(
                            style: .secondary,
                            mode: .transparent,
                            title: "copy_warning.dont_copy".localized,
                            action: {
                                isPresented = false
                            }
                        ),
                    ])
                ),
            ]
        )
    }
}
