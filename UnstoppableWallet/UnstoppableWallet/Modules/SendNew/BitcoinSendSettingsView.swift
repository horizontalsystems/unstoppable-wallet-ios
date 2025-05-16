import Foundation
import Hodler
import SwiftUI
import ThemeKit

struct BitcoinSendSettingsView: View {
    @StateObject var viewModel: BitcoinSendSettingsViewModel
    var onChangeSettings: () -> Void

    @State private var chooseUtxos: Bool = false
    @State private var chooseSortModePresented: Bool = false
    @State private var chooseLockPeriodPresented: Bool = false
    @State private var inputsOutputsDescriptionPresented: Bool = false

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
                                    inputsOutputsDescriptionPresented = true
                                }, label: {
                                    HStack(spacing: .margin8) {
                                        Text("fee_settings.inputs_outputs".localized).textBody()
                                        Image("circle_information_20").themeIcon()
                                    }
                                })

                                Spacer()

                                Button(action: {
                                    chooseSortModePresented = true
                                }) {
                                    Text(viewModel.sortMode.title)
                                }
                                .buttonStyle(SecondaryButtonStyle(rightAccessory: .dropDown))
                            }
                        }
                    }
                    ListSectionFooter(text: "fee_settings.transaction_settings.description".localized)
                }
                VStack(spacing: 0) {
                    ListSection {
                        ListRow {
                            HStack(spacing: .margin8) {
                                Text("fee_settings.time_lock".localized).textBody()

                                Spacer()

                                Button(action: {
                                    chooseLockPeriodPresented = true
                                }) {
                                    HStack(spacing: .margin8) {
                                        if let interval = viewModel.lockTimeInterval {
                                            Text(HodlerPlugin.LockTimeInterval.title(lockTimeInterval: interval)).textCaption(color: .themeLeah)
                                        } else {
                                            Text("send.hodler_locktime_off".localized).textCaption(color: .themeLeah)
                                        }
                                    }
                                }
                                .buttonStyle(SecondaryButtonStyle(rightAccessory: .dropDown))
                            }
                            .alert(
                                isPresented: $chooseLockPeriodPresented,
                                title: "fee_settings.time_lock".localized,
                                viewItems: [.init(text: "send.hodler_locktime_off".localized)] +
                                    HodlerPlugin.LockTimeInterval.allCases.map {
                                        AlertViewItem(text: HodlerPlugin.LockTimeInterval.title(lockTimeInterval: $0))
                                    },
                                onTap: { index in
                                    guard let index else {
                                        return
                                    }
                                    switch index {
                                    case 0: viewModel.lockTimeInterval = nil
                                    case 1: viewModel.lockTimeInterval = .hour
                                    case 2: viewModel.lockTimeInterval = .month
                                    case 3: viewModel.lockTimeInterval = .halfYear
                                    case 4: viewModel.lockTimeInterval = .year
                                    default: ()
                                    }
                                }
                            )
                        }
                    }

                    ListSectionFooter(text: "fee_settings.time_lock.description".localized)
                }
                VStack(spacing: 0) {
                    ListSection {
                        ListRow {
                            Toggle(isOn: $viewModel.rbfEnabled) {
                                Text("fee_settings.replace_by_fee".localized).themeBody()
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .themeOrange))
                        }
                    }

                    ListSectionFooter(text: "fee_settings.replace_by_fee.description".localized)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .sheet(isPresented: $inputsOutputsDescriptionPresented) {
            InfoView(
                items: [
                    .header1(text: "send.transaction_inputs_outputs_info.title".localized),
                    .text(text: "send.transaction_inputs_outputs_info.description".localized(AppConfig.appName, AppConfig.appName)),
                    .header3(text: "send.transaction_inputs_outputs_info.shuffle.title".localized),
                    .text(text: "send.transaction_inputs_outputs_info.shuffle.description".localized),
                    .header3(text: "send.transaction_inputs_outputs_info.deterministic.title".localized),
                    .text(text: "send.transaction_inputs_outputs_info.deterministic.description".localized),
                ],
                isPresented: $inputsOutputsDescriptionPresented
            )
        }
        .bottomSheet(isPresented: $chooseSortModePresented) {
            VStack(spacing: 0) {
                HStack(spacing: .margin8) {
                    Image("arrow_medium_2_up_right_24").themeIcon(color: .gray)

                    Text("fee_settings.transaction_settings".localized).themeHeadline2()

                    Button(action: {
                        chooseSortModePresented = false
                    }) {
                        Image("close_3_24")
                    }
                }
                .padding(EdgeInsets(top: .margin24, leading: .margin32, bottom: .margin12, trailing: .margin32))

                VStack(spacing: 0) {
                    ListSection {
                        ForEach(TransactionDataSortMode.allCases) { sortMode in
                            ClickableRow(action: {
                                if viewModel.sortMode != sortMode {
                                    viewModel.sortMode = sortMode
                                }

                                chooseSortModePresented = false
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
                    .overlay(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(Color.themeSteel20, lineWidth: .heightOneDp))
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin24, trailing: .margin16))
            }
        }
        .navigationTitle("fee_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("button.reset".localized) {
                    viewModel.reset()
                }
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
}
