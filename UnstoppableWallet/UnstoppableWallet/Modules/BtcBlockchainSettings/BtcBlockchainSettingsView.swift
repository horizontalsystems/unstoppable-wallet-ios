import SDWebImageSwiftUI
import SwiftUI

struct BtcBlockchainSettingsView: View {
    @ObservedObject var viewModel: BtcBlockchainSettingsViewModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var infoPresented = false

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: .margin24) {
                    HighlightedTextView(text: "btc_blockchain_settings.restore_source.alert".localized(viewModel.title))

                    VStack(spacing: 0) {
                        ListSectionInfoHeader(text: "btc_blockchain_settings.restore_source".localized) {
                            infoPresented = true
                        }
                        .sheet(isPresented: $infoPresented) {
                            InfoModule.restoreSourceInfo
                        }

                        ListSection {
                            ForEach(viewModel.restoreModes) { restoreMode in
                                ClickableRow(action: {
                                    viewModel.selectedRestoreMode = restoreMode
                                }) {
                                    VStack(spacing: 1) {
                                        Text(restoreMode.title).themeBody()
                                        Text(restoreMode.description).themeSubhead2()
                                    }

                                    if restoreMode == viewModel.selectedRestoreMode {
                                        Image.checkIcon
                                    }
                                }
                            }
                        }

                        ListSectionFooter(text: "btc_blockchain_settings.restore_source.description".localized)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            } bottomContent: {
                Button(action: {
                    viewModel.onTapSave()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("button.save".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(!viewModel.saveEnabled)
            }
        }
        .navigationBarTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                WebImage(url: URL(string: viewModel.iconUrl))
                    .resizable()
                    .scaledToFit()
                    .frame(width: .iconSize24, height: .iconSize24)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
