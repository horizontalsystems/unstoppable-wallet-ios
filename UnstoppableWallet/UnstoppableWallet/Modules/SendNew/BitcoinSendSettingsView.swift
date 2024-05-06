import Foundation
import SwiftUI

struct BitcoinSendSettingsView: View {
    @StateObject var viewModel: BitcoinSendSettingsViewModel
    var onChangeSettings: () -> Void

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
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
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
                    viewModel.applySettings()
                    onChangeSettings()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(!viewModel.doneEnabled)
            }
        }
    }
}
