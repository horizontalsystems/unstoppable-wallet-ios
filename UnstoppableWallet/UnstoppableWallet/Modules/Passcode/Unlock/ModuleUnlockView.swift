import SwiftUI

struct ModuleUnlockView: View {
    @StateObject private var viewModel: ModuleUnlockViewModel

    @Environment(\.presentationMode) private var presentationMode

    init(biometryAllowed: Bool = false, onUnlock: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ModuleUnlockViewModel(biometryAllowed: biometryAllowed, onUnlock: onUnlock))
    }

    var body: some View {
        UnlockView(viewModel: viewModel)
            .navigationTitle("unlock.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
}
