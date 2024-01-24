import Foundation
import SwiftUI

struct OneInchMultiSwapSettingsView: View {
    @ObservedObject var viewModel: OneInchMultiSwapSettingsViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
                VStack(spacing: .margin24) {
                    VStack(spacing: 0) {
                        headerRow(title: OneInchMultiSwapSettingsViewModel.Section.address.title)
                        inputWithShortCuts(
                            placeholder: viewModel.initialAddress,
                            shortCuts: viewModel.addressShortCuts,
                            text: $viewModel.address,
                            cautionState: $viewModel.addressCautionState,
                            onTap: { viewModel.onTapAddress(index: $0) },
                            onTapDelete: { viewModel.address = "" }
                        )

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
        .sheet(isPresented: $viewModel.qrScanPresented) {
            ScanQrViewNew { s in
                viewModel.didFetch(s)
            }
        }
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

    @ViewBuilder private func inputWithShortCuts(placeholder: String = "", shortCuts: [ShortCutButtonType], text: Binding<String>, cautionState: Binding<CautionState>, onTap: @escaping (Int) -> (), onTapDelete: @escaping () -> ()) -> some View {
        InputTextRow(vertical: .margin8) {
            ShortCutButtonsView(
                content: {
                    InputTextView(
                        placeholder: placeholder,
                        text: text
                    )
                    .font(.themeBody)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
            },
            text: text,
            items: shortCuts,
            onTap: {
                onTap($0)
            }, onTapDelete: {
                onTapDelete()
            })
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
