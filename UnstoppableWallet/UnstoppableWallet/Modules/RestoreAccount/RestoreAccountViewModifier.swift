import SwiftUI

struct RestoreAccountViewModifier: ViewModifier {
    @ObservedObject var viewModel: TermsAcceptedViewModifierModel
    var onRestore: (() -> Void)?

    init(viewModel: TermsAcceptedViewModifierModel, onRestore: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onRestore = onRestore
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.termsPresented) {
                TermsView(isPresented: $viewModel.termsPresented) {
                    viewModel.modulePresented = true
                }
            }
            .sheet(isPresented: $viewModel.modulePresented) {
                RestoreTypeView(type: .wallet) {
                    if let onRestore {
                        onRestore()
                    } else {
                        viewModel.modulePresented = false
                    }
                }
                .ignoresSafeArea()
            }
    }
}
