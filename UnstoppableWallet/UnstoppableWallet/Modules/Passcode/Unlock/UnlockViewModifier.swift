import SwiftUI

struct UnlockViewModifier: ViewModifier {
    @ObservedObject var viewModel: UnlockViewModifierModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.unlockPresented) {
                ThemeNavigationStack {
                    ModuleUnlockView {
                        DispatchQueue.main.async {
                            viewModel.onUnlock?()
                        }
                    }
                }
            }
    }
}
