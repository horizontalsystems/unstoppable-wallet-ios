import MarketKit
import SwiftUI

struct MultiSwapAddressView: View {
    @ObservedObject var viewModel: AddressMultiSwapSettingsViewModel

    @FocusState var isAddressFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("swap.advanced_settings.recipient_address".localized).textSubhead1()
                Spacer()
            }
            .padding(EdgeInsets(top: .margin6, leading: .margin16, bottom: .margin6, trailing: .margin16))

            AddressViewNew(
                initial: .init(
                    blockchainType: viewModel.blockchainType,
                    showContacts: true
                ),
                text: $viewModel.address,
                result: $viewModel.addressResult
            )
            .focused($isAddressFocused)
            .onChange(of: isAddressFocused) { active in
                viewModel.changeAddressFocus(active: active)
            }
            .modifier(CautionBorder(cautionState: $viewModel.addressCautionState))
            .modifier(CautionPrompt(cautionState: $viewModel.addressCautionState))

            Text("swap.advanced_settings.recipient.footer".localized)
                .themeSubhead2()
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        }
    }
}
