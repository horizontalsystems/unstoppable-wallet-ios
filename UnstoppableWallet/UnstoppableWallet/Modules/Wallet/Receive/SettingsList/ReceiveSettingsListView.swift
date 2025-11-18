import MarketKit
import SwiftUI

struct ReceiveSettingsListView: View {
    @StateObject var viewModel: ReceiveSettingsViewModel

    @Binding var path: NavigationPath
    private var onDismiss: (() -> Void)?

    @Environment(\.presentationMode) private var presentationMode

    init(viewModel: ReceiveSettingsViewModel, path: Binding<NavigationPath>, onDismiss: (() -> Void)? = nil) {
        _path = path
        self.onDismiss = onDismiss

        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ThemeView(style: .list) {
            ThemeList {
                Section {
                    ListForEach(viewModel.viewItems) { viewItem in
                        cell(viewItem: viewItem)
                    }
                } header: {
                    ThemeText("receive_address_format_select.description".localized, style: .subhead, colorStyle: .secondary)
                        .padding(.horizontal, .margin32)
                        .padding(.top, .margin12)
                        .padding(.bottom, .margin32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.themeTyler)
                        .listRowInsets(EdgeInsets())
                }

                if let bottomDescription = viewModel.highlightedBottomDescription {
                    AlertCardView(.init(
                        text: bottomDescription,
                        type: .caution
                    ))
                    .padding(.top, .margin24)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .navigationTitle("receive_address_format_select.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Wallet.self) { wallet in
            ReceiveAddressModule.instance(wallet: wallet, path: $path, onDismiss: onDismiss)
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

    @ViewBuilder private func cell(viewItem: ReceiveSettingsViewModel.ViewItem) -> some View {
        Cell(
            middle: {
                MultiText(title: viewItem.title, subtitle: viewItem.subtitle)
            },
            right: {
                Image.disclosureIcon
            },
            action: {
                if let wallet = viewModel.item(uid: viewItem.uid) {
                    path.append(wallet)
                }
            }
        )
    }
}
