import Foundation
import SwiftUI

struct OneInchMultiSwapSettingsView: View {
    @ObservedObject var viewModel: OneInchMultiSwapSettingsViewModel
    @FocusState var isAddressFocused: Bool {
        didSet {
            print("Set focused: \(isAddressFocused)")
        }
    }

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                VStack(spacing: 0) {
                    headerRow(title: OneInchMultiSwapSettingsViewModel.Section.address.title)

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

                    Text(OneInchMultiSwapSettingsViewModel.Section.address.footer)
                        .themeSubhead2()
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
                }

                VStack(spacing: 0) {
                    headerRow(title: OneInchMultiSwapSettingsViewModel.Section.slippage.title)
                    inputWithShortCuts(
                        placeholder: viewModel.initialSlippage.description,
                        shortCuts: viewModel.slippageShortCuts,
                        text: $viewModel.slippage,
                        cautionState: $viewModel.slippageCautionState,
                        onTap: { viewModel.slippage = viewModel.slippage(at: $0).description },
                        onTapDelete: { viewModel.slippage = "" }
                    )

                    Text(OneInchMultiSwapSettingsViewModel.Section.slippage.footer)
                        .themeSubhead2()
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .animation(.default, value: viewModel.addressCautionState)
        .animation(.default, value: viewModel.slippage)
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
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!viewModel.doneEnabled)
            }
        }
    }

    @ViewBuilder private func headerRow(title: String) -> some View {
        HStack {
            Text(title).textSubhead1()
            Spacer()
        }
        .padding(EdgeInsets(top: .margin6, leading: .margin16, bottom: .margin6, trailing: .margin16))
    }

    @ViewBuilder private func inputWithShortCuts(placeholder: String = "", shortCuts: [ShortCutButtonType], text: Binding<String>, cautionState: Binding<CautionState>, onTap: @escaping (Int) -> Void, onTapDelete: @escaping () -> Void) -> some View {
        InputTextRow(vertical: .margin8) {
            ShortcutButtonsView(
                content: {
                    InputTextView(
                        placeholder: placeholder,
                        text: text
                    )
                    .font(.themeBody)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                },
                showDelete: .init(get: { !text.wrappedValue.isEmpty }, set: { _ in }),
                items: shortCuts,
                onTap: {
                    onTap($0)
                }, onTapDelete: {
                    onTapDelete()
                }
            )
        }
        .modifier(CautionBorder(cautionState: cautionState))
        .modifier(CautionPrompt(cautionState: cautionState))
    }
}

extension OneInchMultiSwapSettingsView {
    struct ViewItem {
        let title: String
        let value: String
        let subValue: String?
    }
}

extension OneInchMultiSwapSettingsViewModel.Section {
    var title: String {
        switch self {
        case .address: return "swap.advanced_settings.recipient_address".localized
        case .slippage: return "swap.advanced_settings.slippage".localized
        }
    }

    var footer: String {
        switch self {
        case .address: return "swap.advanced_settings.recipient.footer".localized
        case .slippage: return "swap.advanced_settings.slippage.footer".localized
        }
    }
}
