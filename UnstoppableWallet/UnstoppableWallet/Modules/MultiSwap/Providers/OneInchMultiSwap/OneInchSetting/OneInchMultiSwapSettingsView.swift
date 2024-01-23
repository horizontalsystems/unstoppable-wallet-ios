import Foundation
import SwiftUI

struct OneInchMultiSwapSettingsView: View {
    @ObservedObject var viewModel: OneInchMultiSwapSettingsViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: .margin24) {
                    VStack(spacing: 0) {
                        headerRow(title: OneInchMultiSwapSettingsViewModel.Section.slippage.title)
                        inputNumberWithShortCuts(
                            placeholder: "Def_Value",
                            text: $viewModel.slippage,
                            cautionState: $viewModel.slippageCautionState
                        )
                    }
                }
            } bottomContent: {
                Button(action: {
                    viewModel.onApply()
                }) {
                    Text("button.apply".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(!viewModel.applyEnabled)
            }
        }
        .animation(.default, value: viewModel.address)
        .animation(.default, value: viewModel.slippage)
        .navigationTitle("swap.advanced_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized.uppercased()) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    @ViewBuilder private func headerRow(title: String) -> some View {
        Text(title.uppercased())
            .textSubhead1()
            .frame(alignment: .leading)
    }

    @ViewBuilder private func inputNumberWithShortCuts(placeholder: String = "", text: Binding<String>, cautionState: Binding<CautionState>) -> some View {
        InputTextRow(vertical: .margin8) {
            ShortCutButtonsView(
                content: {
                    InputTextView(
                        placeholder: placeholder,
                        text: text
                    )
                    .font(.themeBody)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
            },
            text: text,
            items: ["0.1%", "1%"],
            onTap: {
                print("Tapped button number \($0)")
                viewModel.slippage = "54"
            }, onTapDelete: {
                viewModel.slippage = ""
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
