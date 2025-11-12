import MarketKit
import SwiftUI

struct ReceiveBlockhainListView: View {
    @StateObject var viewModel: ReceiveBlockchainListViewModel

    private let account: Account
    @Binding var path: NavigationPath
    private var onDismiss: (() -> Void)?

    @Environment(\.presentationMode) private var presentationMode

    init(account: Account, fullCoin: FullCoin, path: Binding<NavigationPath>, onDismiss: (() -> Void)? = nil) {
        self.account = account
        _path = path
        self.onDismiss = onDismiss

        _viewModel = StateObject(wrappedValue: ReceiveBlockchainListViewModel(fullCoin: fullCoin, accountType: account.type))
    }

    var body: some View {
        ThemeView(style: .list) {
            ThemeList {
                Section {
                    ListForEach(viewModel.viewItems) { viewItem in
                        cell(viewItem: viewItem)
                    }
                } header: {
                    ThemeText("receive_network_select.description".localized, style: .subhead, colorStyle: .secondary)
                        .padding(.horizontal, .margin32)
                        .padding(.top, .margin12)
                        .padding(.bottom, .margin32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.themeTyler)
                        .listRowInsets(EdgeInsets())
                }
            }
        }
        .navigationTitle("receive_network_select.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Token.self) { token in
            ReceiveModule.view(token: token, account: account, path: $path, onDismiss: onDismiss)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("button.cancel".localized) {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .accentColor(.themeGray)
    }

    @ViewBuilder private func cell(viewItem: ReceiveBlockchainListViewModel.ViewItem) -> some View {
        Cell(
            left: {
                IconView(url: viewItem.imageUrl)
            },
            middle: {
                MultiText(title: viewItem.title, subtitle: viewItem.subtitle)
            },
            right: {
                Image.disclosureIcon
            },
            action: {
                if let token = viewModel.item(uid: viewItem.uid) {
                    path.append(token)
                }
            }
        )
    }
}
