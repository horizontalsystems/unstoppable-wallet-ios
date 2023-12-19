import Kingfisher
import SwiftUI

struct BtcBlockchainSettingsView: View {
    @ObservedObject var viewModel: BtcBlockchainSettingsViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: .margin32) {
                    VStack(spacing: .margin32) {
                        Text("btc_blockchain_settings.restore_source.description".localized)
                            .themeSubhead2()
                            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

                        ListSection {
                            ForEach(viewModel.restoreModes, id: \.restoreMode.id) { restoreMode in
                                ClickableRow(action: {
                                    viewModel.selectedRestoreMode = restoreMode.restoreMode
                                }) {
                                    switch restoreMode.icon {
                                    case let .local(name):
                                        Image(name)
                                    case let .remote(url):
                                        KFImage.url(URL(string: url))
                                            .resizable()
                                            .frame(width: .iconSize32, height: .iconSize32)
                                    }

                                    VStack(spacing: 1) {
                                        Text(restoreMode.title).themeBody()
                                        Text(restoreMode.description).themeSubhead2()
                                    }

                                    if restoreMode.restoreMode == viewModel.selectedRestoreMode {
                                        Image.checkIcon
                                    }
                                }
                            }
                        }
                    }

                    HighlightedTextView(text: "btc_blockchain_settings.restore_source.alert".localized(viewModel.title))
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
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                KFImage.url(URL(string: viewModel.iconUrl))
                    .resizable()
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
