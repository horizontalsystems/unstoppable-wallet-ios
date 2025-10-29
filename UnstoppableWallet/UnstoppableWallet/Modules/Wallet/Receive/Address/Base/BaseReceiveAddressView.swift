import Combine

import SwiftUI

private let qrSize: CGFloat = 203
private let appIconSize: CGFloat = 47

struct BaseReceiveAddressView<Content: View>: View {
    @StateObject private var viewModel: BaseReceiveAddressViewModel
    private let content: () -> Content

    var onDismiss: (() -> Void)?

    @Environment(\.presentationMode) private var presentationMode

    init(viewModel: BaseReceiveAddressViewModel, @ViewBuilder content: @escaping () -> Content, onDismiss: (() -> Void)?) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.content = content

        self.onDismiss = onDismiss
    }

    var body: some View {
        ScrollableThemeView {
            ReceiveAddressBodyView(viewModel: viewModel, content: content)
        }
        .alertButtonTint(color: .themeJacob)
        .onFirstAppear {
            viewModel.onFirstAppear()
        }
        .onReceive(viewModel.popupPublisher) { popup in
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BottomSheetView.instance(
                    title: popup.title,
                    items: [
                        .text(text: popup.description.text),
                        .buttonGroup(.init(buttons: viewModel.popupButtons(mode: popup.mode, isPresented: isPresented))),
                    ],
                    isPresented: isPresented
                )
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("button.done".localized) {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .accentColor(.themeGray)
    }
}
