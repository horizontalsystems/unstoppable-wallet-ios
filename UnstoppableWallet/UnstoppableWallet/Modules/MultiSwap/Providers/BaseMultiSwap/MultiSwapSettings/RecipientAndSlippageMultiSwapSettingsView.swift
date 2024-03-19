import Foundation
import MarketKit
import SwiftUI

struct RecipientAndSlippageMultiSwapSettingsView: View {
    @StateObject var viewModel: ViewModel
    var onChangeSettings: () -> Void

    @Environment(\.presentationMode) private var presentationMode

    init(tokenIn: Token, storage: MultiSwapSettingStorage, onChangeSettings: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: ViewModel(tokenIn: tokenIn, storage: storage))
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
        .animation(.default, value: viewModel.addressViewModel.addressCautionState)
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

extension RecipientAndSlippageMultiSwapSettingsView {
    class ViewModel: BaseMultiSwapSettingsViewModel {
        let addressViewModel: AddressMultiSwapSettingsViewModel
        let slippageViewModel: SlippageMultiSwapSettingsViewModel

        init(tokenIn: Token, storage: MultiSwapSettingStorage) {
            addressViewModel = AddressMultiSwapSettingsViewModel(storage: storage, blockchainType: tokenIn.blockchainType)
            slippageViewModel = SlippageMultiSwapSettingsViewModel(storage: storage)

            super.init(fields: [addressViewModel, slippageViewModel])
        }
    }
}
