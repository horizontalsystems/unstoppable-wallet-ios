import SwiftUI

struct ModuleUnlockView: View {
    @ObservedObject var viewModel: ModuleUnlockViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        UnlockView(viewModel: viewModel, autoDismiss: true)
            .navigationTitle("unlock.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
}
