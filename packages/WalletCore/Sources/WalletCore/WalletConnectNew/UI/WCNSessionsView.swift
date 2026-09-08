import Kingfisher
import SwiftUI

struct WCNSessionsView: View {
    @StateObject private var viewModel = WCNSessionsViewModel()

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                if viewModel.items.isEmpty {
                    PlaceholderViewNew(icon: "warning_filled", subtitle: "wallet_connect.list.empty_view_text".localized)
                } else {
                    ScrollView {
                        VStack(spacing: .margin16) {
                            ForEach(viewModel.items) { item in
                                ListSection {
                                    // an approved session is never opened as a screen (parity with Android): the row only lists it
                                    ListRow {
                                        KFImage.url(item.iconUrl)
                                            .resizable()
                                            .placeholder { RoundedRectangle(cornerRadius: .cornerRadius8).fill(Color.themeBlade) }
                                            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8))
                                            .frame(width: .iconSize32, height: .iconSize32)

                                        VStack(spacing: 1) {
                                            Text(item.session.dAppName).themeBody()
                                            Text(item.host).themeSubhead2()
                                        }

                                        Button(action: { disconnect(item: item) }) {
                                            Image("trash_20").themeIcon()
                                        }
                                    }

                                    ForEach(item.requests) { request in
                                        ClickableRow(action: { viewModel.open(request: request) }) {
                                            Text("wallet_connect.list.requests".localized).textSubhead2()
                                            Spacer()
                                            Text(request.label).textSubhead1(color: .themeLeah)
                                            Image.disclosureIcon
                                        }
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                }
            } bottomContent: {
                Button(action: { scan() }) {
                    Text("wallet_connect_list.new_connection".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .onAppear { viewModel.refresh() }
        .navigationTitle("wallet_connect_list.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func scan() {
        Coordinator.shared.present { isPresented in
            ScanQrViewNew(reportAfterDismiss: true, isPresented: isPresented) { uri in
                viewModel.pair(uri: uri)
            }
            .ignoresSafeArea()
        }
    }

    private func disconnect(item: WCNSessionsViewModel.Item) {
        WCNPresenter.presentDisconnect(dAppName: item.session.dAppName, host: item.host, iconUrl: item.iconUrl?.absoluteString) {
            viewModel.disconnect(item: item)
        }
    }
}
