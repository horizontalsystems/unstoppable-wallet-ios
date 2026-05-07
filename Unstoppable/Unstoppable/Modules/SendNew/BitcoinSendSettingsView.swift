import Foundation
import Hodler
import SwiftUI

struct BitcoinSendSettingsView: View {
    @StateObject var viewModel: BitcoinSendSettingsViewModel
    var onChangeSettings: () -> Void

    @State private var path = NavigationPath()

    @Environment(\.presentationMode) private var presentationMode

    init(handler: BitcoinPreSendHandler, onChangeSettings: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: BitcoinSendSettingsViewModel(handler: handler))
        self.onChangeSettings = onChangeSettings
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ScrollableThemeView {
                VStack(spacing: .margin32) {
                    VStack(spacing: 0) {
                        ListSection {
                            row(
                                title: "send.unspent_outputs".localized,
                                subtitle: "send.unspent_outputs.description".localized,
                                value: viewModel.utxos,
                                action: {
                                    path.append(Route.outputSelector)
                                }
                            )

                            row(
                                title: "fee_settings.inputs_outputs".localized,
                                subtitle: "fee_settings.inputs_outputs.description".localized,
                                value: viewModel.sortMode.title,
                                action: {
                                    Coordinator.shared.present(type: .alert) { isPresented in
                                        OptionAlertView(
                                            title: "fee_settings.inputs_outputs".localized,
                                            viewItems: TransactionDataSortMode.allCases.map { .init(text: $0.title, selected: viewModel.sortMode == $0) },
                                            onSelect: { index in
                                                viewModel.sortMode = TransactionDataSortMode.allCases[index]
                                            },
                                            isPresented: isPresented
                                        )
                                    }
                                }
                            )

                            if viewModel.lockTimeIntervalState != .inactive {
                                row(
                                    title: "fee_settings.time_lock".localized,
                                    subtitle: "fee_settings.time_lock.description".localized,
                                    value: viewModel.lockTimeIntervalTitle,
                                    action: viewModel.lockTimeIntervalState == .enabled ? {
                                        Coordinator.shared.present(type: .alert) { isPresented in
                                            OptionAlertView(
                                                title: "fee_settings.time_lock".localized,
                                                viewItems: [.init(text: "send.hodler_locktime_off".localized, selected: viewModel.lockTimeInterval == nil)] +
                                                    HodlerPlugin.LockTimeInterval.allCases.map {
                                                        AlertViewItem(text: HodlerPlugin.LockTimeInterval.title(lockTimeInterval: $0), selected: viewModel.lockTimeInterval == $0)
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
                                    } : nil
                                )
                            }

                            if viewModel.rbfAllowed {
                                row(
                                    title: "fee_settings.replace_by_fee".localized,
                                    subtitle: "fee_settings.replace_by_fee.description".localized,
                                    isOn: $viewModel.rbfEnabled
                                )
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle("fee_settings".localized)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .outputSelector:
                    OutputSelectorView2(handler: viewModel.handler)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.reset()
                    }) {
                        Image("reset")
                    }
                    .disabled(!viewModel.resetEnabled)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onChangeSettings()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("check")
                    }
                    .modifier(ConfirmationButtonStyle())
                }
            }
        }
    }

    @ViewBuilder private func row(title: String, subtitle: String, value: String, action: (() -> Void)?) -> some View {
        let enabled = action != nil

        Cell(
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                ThemeText(
                    value,
                    style: .subheadSB,
                    colorStyle: enabled ? .primary : .secondary
                )
                .arrow(
                    style: .dropdown,
                    colorStyle: enabled ? .primary : .secondary
                )
            },
            action: action
        )
    }

    @ViewBuilder private func row(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Cell(
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                ThemeToggle(isOn: isOn)
            }
        )
    }
}

extension BitcoinSendSettingsView {
    private enum Route: Hashable {
        case outputSelector
    }
}
