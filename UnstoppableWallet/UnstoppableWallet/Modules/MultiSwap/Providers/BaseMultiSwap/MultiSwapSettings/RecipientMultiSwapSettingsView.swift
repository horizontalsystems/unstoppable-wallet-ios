import Foundation
import MarketKit
import SwiftUI

struct RecipientMultiSwapSettingsView: View {
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

        init(tokenIn: Token, storage: MultiSwapSettingStorage) {
            addressViewModel = AddressMultiSwapSettingsViewModel(storage: storage, token: tokenIn)

            super.init(fields: [addressViewModel])
        }
    }
}
