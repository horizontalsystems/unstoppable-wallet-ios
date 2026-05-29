import SwiftUI

struct ModuleUnlockView: View {
    @StateObject private var viewModel: ModuleUnlockViewModel

    @Environment(\.presentationMode) private var presentationMode

    init(biometryAllowed: Bool = true, onUnlock: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ModuleUnlockViewModel(biometryAllowed: biometryAllowed, onUnlock: onUnlock))
    }

    var body: some View {
        UnlockView(viewModel: viewModel)
            .navigationTitle("unlock.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("close")
                    }
                }
            }
    }
}
