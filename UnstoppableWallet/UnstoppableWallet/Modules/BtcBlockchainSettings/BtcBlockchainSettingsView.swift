import SwiftUI
import SDWebImageSwiftUI

struct BtcBlockchainSettingsView: View {
    @ObservedObject var viewModel: BtcBlockchainSettingsViewModel

    @Environment(\.presentationMode) var presentationMode
    @State var infoPresented = false

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                VStack(spacing: 0) {
                    ScrollView {
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
                                                Image("check_1_20").themeIcon(color: .themeJacob)
                                            }
                                        }
                                    }
                                }

                                ListSectionFooter(text: "btc_blockchain_settings.restore_source.description".localized)
                            }
                        }
                                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }

                    Button(action: {
                        viewModel.onTapSave()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save")
                    }
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

}
