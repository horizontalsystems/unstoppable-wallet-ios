import Foundation
import SwiftUI

struct RecipientAndSlippageMultiSwapSettingsView: View {
    @ObservedObject var viewModel: BaseMultiSwapSettingsViewModel
    @ObservedObject var addressViewModel: AddressMultiSwapSettingsViewModel
    @ObservedObject var slippageViewModel: SlippageMultiSwapSettingsViewModel
    var onChangeSettings: () -> ()

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                MultiSwapAddressView(viewModel: addressViewModel)
                MultiSwapSlippageView(viewModel: slippageViewModel)
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .animation(.default, value: addressViewModel.addressCautionState)
        .animation(.default, value: slippageViewModel.slippageCautionState)
        .navigationTitle("swap.advanced_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("button.reset".localized) {
                    viewModel.onReset()
                }
                .disabled(!viewModel.resetEnabled)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.done".localized) {
                    viewModel.onDone()
                    onChangeSettings()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!viewModel.doneEnabled)
            }
        }
    }
}
