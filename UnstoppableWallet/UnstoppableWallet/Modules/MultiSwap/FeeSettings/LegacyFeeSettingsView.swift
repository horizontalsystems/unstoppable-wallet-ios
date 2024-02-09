import Foundation
import MarketKit
import SwiftUI

struct LegacyFeeSettingsView: View {
    @ObservedObject var viewModel: LegacyFeeSettingsViewModel
    var onChangeSettings: () -> Void
    @Environment(\.presentationMode) private var presentationMode

    init(service: EvmMultiSwapTransactionService, feeViewItemFactory: FeeViewItemFactory, onChangeSettings: @escaping () -> Void) {
        viewModel = LegacyFeeSettingsViewModel(service: service, feeViewItemFactory: feeViewItemFactory)
        self.onChangeSettings = onChangeSettings
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                VStack(spacing: 0) {
                    headerRow(
                        title: Section.gasPrice.title,
                        description: .init(
                            title: Section.gasPrice.title,
                            description: Section.gasPrice.info
                        )
                    )
                    inputNumberWithSteps(
                        placeholder: "",
                        text: $viewModel.gasPrice,
                        cautionState: $viewModel.gasPriceCautionState,
                        onTap: viewModel.stepChangeGasPrice
                    )
                }

                VStack(spacing: 0) {
                    headerRow(
                        title: Section.nonce.title,
                        description: .init(
                            title: Section.nonce.title,
                            description: Section.nonce.info
                        )
                    )
                    inputNumberWithSteps(
                        placeholder: "",
                        text: $viewModel.nonce,
                        cautionState: $viewModel.nonceCautionState,
                        onTap: viewModel.stepChangeNonce
                    )
                }

                if let caution = viewModel.cautionState.caution {
                    VStack(spacing: 32) {
                        HighlightedTitledTextView(caution: caution)
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .animation(.default, value: viewModel.gasPriceCautionState)
        .animation(.default, value: viewModel.nonceCautionState)
        .navigationTitle("fee_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("button.reset".localized) {
                    viewModel.onReset()
                }.disabled(!viewModel.resetEnabled)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.done".localized) {
                    onChangeSettings()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    @ViewBuilder private func row(viewItem: ViewItem, description: AlertView.InfoDescription) -> some View {
        HStack(spacing: .margin8) {
            Text(viewItem.title)
                .textSubhead2()
                .modifier(Informed(description: description))

            Spacer()

            VStack(spacing: 1) {
                Text(viewItem.value).textSubhead1(color: .themeLeah)

                if let subValue = viewItem.subValue {
                    Text(subValue).textSubhead2()
                }
            }
        }
        .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin12, trailing: .margin16))
        .frame(minHeight: .heightCell56)
    }

    @ViewBuilder private func headerRow(title: String, description: AlertView.InfoDescription) -> some View {
        Text(title)
            .textSubhead1()
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(Informed(description: description))
    }

    @ViewBuilder private func inputNumberWithSteps(placeholder: String = "", text: Binding<String>, cautionState: Binding<FieldCautionState>, onTap: @escaping (StepChangeButtonsViewDirection) -> Void) -> some View {
        InputTextRow(vertical: .margin8) {
            StepChangeButtonsView(content: {
                InputTextView(
                    placeholder: placeholder,
                    text: text
                )
                .font(.themeBody)
                .keyboardType(.numberPad)
                .autocorrectionDisabled()
            }, onTap: onTap)
        }
        .modifier(FieldCautionBorder(cautionState: cautionState))
    }
}

extension LegacyFeeSettingsView {
    struct ViewItem {
        let title: String
        let value: String
        let subValue: String?
    }

    enum Section: Int {
        case gasPrice, nonce

        var title: String {
            switch self {
            case .gasPrice: return "fee_settings.gas_price".localized
            case .nonce: return "evm_send_settings.nonce".localized
            }
        }

        var info: String {
            switch self {
            case .gasPrice: return "fee_settings.gas_price.info".localized
            case .nonce: return "evm_send_settings.nonce.info".localized
            }
        }
    }
}
