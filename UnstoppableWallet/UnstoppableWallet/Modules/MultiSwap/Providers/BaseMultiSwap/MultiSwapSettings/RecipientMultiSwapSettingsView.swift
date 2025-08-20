import Foundation
import MarketKit
import SwiftUI

struct RecipientMultiSwapSettingsView: View {
    @StateObject var viewModel: ViewModel
    var onChangeSettings: () -> Void

    @Environment(\.presentationMode) private var presentationMode

    init(tokenOut: Token, storage: MultiSwapSettingStorage, onChangeSettings: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: ViewModel(tokenOut: tokenOut, storage: storage))
        self.onChangeSettings = onChangeSettings
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                MultiSwapAddressView(viewModel: viewModel.addressViewModel)
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
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

extension RecipientMultiSwapSettingsView {
    class ViewModel: BaseMultiSwapSettingsViewModel {
        let addressViewModel: AddressMultiSwapSettingsViewModel

        init(tokenOut: Token, storage: MultiSwapSettingStorage) {
            addressViewModel = AddressMultiSwapSettingsViewModel(storage: storage, token: tokenOut)

            super.init(fields: [addressViewModel])
        }
    }
}
