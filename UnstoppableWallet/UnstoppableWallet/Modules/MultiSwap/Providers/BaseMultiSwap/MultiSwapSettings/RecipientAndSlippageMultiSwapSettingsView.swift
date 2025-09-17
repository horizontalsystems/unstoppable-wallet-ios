import Foundation
import MarketKit
import SwiftUI

struct RecipientAndSlippageMultiSwapSettingsView: View {
    @StateObject var viewModel: ViewModel
    var onChangeSettings: () -> Void

    @Environment(\.presentationMode) private var presentationMode

    init(tokenOut: Token, storage: MultiSwapSettingStorage, slippageMode: SlippageMultiSwapSettingsViewModel.SlippageMode, onChangeSettings: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: ViewModel(tokenOut: tokenOut, storage: storage, mode: slippageMode))
        self.onChangeSettings = onChangeSettings
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                MultiSwapAddressView(viewModel: viewModel.addressViewModel)
                MultiSwapSlippageView(viewModel: viewModel.slippageViewModel)
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .animation(.default, value: viewModel.slippageViewModel.slippageCautionState)
        .navigationTitle("swap.advanced_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("button.reset".localized) {
                    viewModel.onReset()
                }
                .disabled(!viewModel.resetEnabled)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("button.done".localized) {
                    viewModel.onDone()
                    onChangeSettings()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!viewModel.doneEnabled)
            }
        }
        .accentColor(Color.themeJacob)
    }
}

extension RecipientAndSlippageMultiSwapSettingsView {
    
    class ViewModel: BaseMultiSwapSettingsViewModel {
        let addressViewModel: AddressMultiSwapSettingsViewModel
        let slippageViewModel: SlippageMultiSwapSettingsViewModel

        init(tokenOut: Token, storage: MultiSwapSettingStorage, mode: SlippageMultiSwapSettingsViewModel.SlippageMode) {
            addressViewModel = AddressMultiSwapSettingsViewModel(storage: storage, token: tokenOut)
            slippageViewModel = SlippageMultiSwapSettingsViewModel(storage: storage, mode: mode)

            super.init(fields: [addressViewModel, slippageViewModel])
        }
    }
}
