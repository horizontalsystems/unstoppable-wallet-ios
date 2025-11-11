import Foundation
import Hodler
import SwiftUI

struct BitcoinSendSettingsView: View {
    @StateObject var viewModel: BitcoinSendSettingsViewModel
    var onChangeSettings: () -> Void

    @State private var chooseUtxos: Bool = false

    @Environment(\.presentationMode) private var presentationMode

    init(handler: BitcoinPreSendHandler, onChangeSettings: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: BitcoinSendSettingsViewModel(handler: handler))
        self.onChangeSettings = onChangeSettings
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                VStack(spacing: 0) {
                    ListSection {
                        NavigationRow(
                            destination: { OutputSelectorView2(handler: viewModel.handler) }
                        ) {
                            HStack(spacing: .margin8) {
                                Text("send.unspent_outputs".localized).textBody()

                                Spacer()

                                HStack(spacing: .margin8) {
                                    Text(viewModel.utxos).textSubhead1(color: .themeLeah)
                                    Image("edit2_20").themeIcon(color: .gray)
                                }
                            }
                        }
                    }
                    ListSectionFooter(text: "send.unspent_outputs.description".localized)
                }
                VStack(spacing: 0) {
                    ListSection {
                        ListRow {
                            HStack(spacing: .margin8) {
                                Button(action: {
                                    Coordinator.shared.present { isPresented in
                                        InfoView(
                                            items: [
                                                .header1(text: "send.transaction_inputs_outputs_info.title".localized),
                                                .text(text: "send.transaction_inputs_outputs_info.description".localized(AppConfig.appName, AppConfig.appName)),
                                                .header3(text: "send.transaction_inputs_outputs_info.shuffle.title".localized),
                                                .text(text: "send.transaction_inputs_outputs_info.shuffle.description".localized),
                                                .header3(text: "send.transaction_inputs_outputs_info.deterministic.title".localized),
                                                .text(text: "send.transaction_inputs_outputs_info.deterministic.description".localized),
                                            ],
                                            isPresented: isPresented
                                        )
                                    }
                                }, label: {
                                    HStack(spacing: .margin8) {
                                        Text("fee_settings.inputs_outputs".localized).textBody()
                                        Image("circle_information_20").themeIcon()
                                    }
                                })

                                Spacer()

                                Button(action: {
                                    Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                        sortModeView(isPresented: isPresented)
                                    }
                                }) {
                                    Text(viewModel.sortMode.title)
                                }
                                .buttonStyle(SecondaryButtonStyle(rightAccessory: .dropDown))
                            }
                        }
                    }
                    ListSectionFooter(text: "fee_settings.transaction_settings.description".localized(viewModel.coinCode))
                }
                if viewModel.lockTimeIntervalState != .inactive {
                    VStack(spacing: 0) {
                        ListSection {
                            ListRow {
                                HStack(spacing: .margin8) {
                                    Text("fee_settings.time_lock".localized).textBody()

                                    Spacer()

                                    Button(action: {
                                        Coordinator.shared.present(type: .alert) { isPresented in
                                            OptionAlertView(
                                                title: "fee_settings.time_lock".localized,
                                                viewItems: [.init(text: "send.hodler_locktime_off".localized)] +
                                                    HodlerPlugin.LockTimeInterval.allCases.map {
                                                        AlertViewItem(text: HodlerPlugin.LockTimeInterval.title(lockTimeInterval: $0))
                                                    },
                                                onSelect: { index in
                                                    switch index {
                                                    case 0: viewModel.lockTimeInterval = nil
                                                    default: viewModel.lockTimeInterval = HodlerPlugin.LockTimeInterval.allCases[index - 1]
                                                    }
                                                },
                                                isPresented: isPresented
                                            )
                                        }
                                    }) {
                                        HStack(spacing: .margin8) {
                                            if viewModel.lockTimeIntervalState == .enabled,
                                               let interval = viewModel.lockTimeInterval
                                            {
                                                Text(HodlerPlugin.LockTimeInterval.title(lockTimeInterval: interval)).textCaption(color: .themeLeah)
                                            } else {
                                                Text("send.hodler_locktime_off".localized).textCaption(color: .themeLeah)
                                            }
                                        }
                                    }
                                    .buttonStyle(SecondaryButtonStyle(rightAccessory: .dropDown))
                                    .disabled(viewModel.lockTimeIntervalState == .disabled)
                                }
                            }
                        }

                        ListSectionFooter(text: "fee_settings.time_lock.description".localized)
                    }
                }
                if viewModel.rbfAllowed {
                    VStack(spacing: 0) {
                        ListSection {
                            ListRow {
                                Toggle(isOn: $viewModel.rbfEnabled) {
                                    Text("fee_settings.replace_by_fee".localized).themeBody()
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                            }
                        }

                        ListSectionFooter(text: "fee_settings.replace_by_fee.description".localized)
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("fee_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("button.reset".localized) {
                    viewModel.reset()
                }
                .foregroundStyle(viewModel.resetEnabled ? Color.themeJacob : Color.themeGray)
                .disabled(!viewModel.resetEnabled)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("button.done".localized) {
                    onChangeSettings()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    @ViewBuilder private func sortModeView(isPresented: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            BSTitleView(
                icon: "arrow_medium_2_up_right_24",
                title: "fee_settings.transaction_settings".localized
            )

            VStack(spacing: 0) {
                ListSection {
                    ForEach(TransactionDataSortMode.allCases) { sortMode in
                        ClickableRow(action: {
                            if viewModel.sortMode != sortMode {
                                viewModel.sortMode = sortMode
                            }

                            isPresented.wrappedValue = false
                        }) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(sortMode.title).textBody()
                                Text(sortMode.description).textSubhead2()
                            }

                            Spacer()

                            if viewModel.sortMode == sortMode {
                                Image.checkIcon
                            }
                        }
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(Color.themeBlade, lineWidth: .heightOneDp))
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin24, trailing: .margin16))
        }
    }
}
