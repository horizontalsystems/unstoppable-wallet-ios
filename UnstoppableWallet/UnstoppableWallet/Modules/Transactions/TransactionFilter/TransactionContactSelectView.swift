import Kingfisher
import MarketKit
import SwiftUI

struct TransactionContactSelectView: View {
    @ObservedObject var viewModel: TransactionContactSelectViewModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var searchText: String = ""

    init(transactionFilterViewModel: TransactionFilterViewModel) {
        _viewModel = ObservedObject(wrappedValue: TransactionContactSelectViewModel(transactionFilterViewModel: transactionFilterViewModel))
    }

    var body: some View {
        ThemeView {
            VStack(spacing: .margin12) {
                if !viewModel.contacts.isEmpty {
                    SearchBar(text: $searchText, prompt: "placeholder.search".localized)
                }

                Text("transaction_filter.description".localized(
                    viewModel.allowedBlockchainsForContact.map(\.name).joined(separator: ", ")
                ))
                .themeSubhead2()
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

                if !viewModel.contacts.isEmpty {
                    ScrollableThemeView {
                        ListSection {
                            ClickableRow(action: {
                                viewModel.set(currentContact: nil)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image("paper_contract_24").themeIcon()
                                Text("transaction_filter.all_contacts").themeBody()

                                if viewModel.currentContact == nil {
                                    Image.checkIcon
                                }
                            }

                            ForEach(searchResults, id: \.self) { contact in
                                ClickableRow(action: {
                                    viewModel.set(currentContact: contact)
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image("user_24").themeIcon()

                                    Text(contact.name).textBody()
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    if viewModel.currentContact == contact {
                                        Image.checkIcon
                                    }
                                }
                            }
                        }
                        .themeListStyle(.transparent)
                        .padding(.bottom, .margin32)
                    }
                } else {
                    PlaceholderViewNew(image: Image("not_found_48"), text: "no suitable contacts".localized)
                }
            }
            .navigationTitle("transaction_filter.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    var searchResults: [Contact] {
        let text = searchText.trimmingCharacters(in: .whitespaces)

        if text.isEmpty {
            return viewModel.contacts
        } else {
            return viewModel.contacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(text) ||
                    contact.addresses.contains(where: { $0.address.localizedCaseInsensitiveContains(text) })
            }
        }
    }
}
