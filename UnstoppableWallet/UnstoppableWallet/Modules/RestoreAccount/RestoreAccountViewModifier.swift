import SwiftUI

struct RestoreAccountViewModifier: ViewModifier {
    @ObservedObject var viewModel: TermsAcceptedViewModifierModel
    private var type: BackupModule.Source.Abstract
    private var onRestore: (() -> Void)?

    init(viewModel: TermsAcceptedViewModifierModel, type: BackupModule.Source.Abstract, onRestore: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.type = type
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
                RestoreTypeView(type: type) {
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
