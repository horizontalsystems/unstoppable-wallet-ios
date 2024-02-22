import Kingfisher
import MarketKit
import SwiftUI

struct TransactionContactSelectView: View {
    @ObservedObject var viewModel: TransactionFilterViewModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var searchText: String = ""

    var body: some View {
        ThemeView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, prompt: "placeholder.search".localized)

                ScrollableThemeView {
                    ListSection {
                        ClickableRow(action: {
                            viewModel.set(token: nil)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image("user_24").themeIcon()
                            Text("transaction_filter.all_contacts").themeBody()

                            if viewModel.contact == nil {
                                Image.checkIcon
                            }
                        }

                        ForEach(searchResults, id: \.self) { contact in
                            ClickableRow(action: {
                                viewModel.set(contact: contact)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image("user_24").themeIcon()

                                Text(contact.name).textBody()
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if viewModel.contact == contact {
                                    Image.checkIcon
                                }
                            }
                        }
                    }
                    .themeListStyle(.transparent)
                    .padding(.bottom, .margin32)
                }
            }
            .navigationTitle("transaction_filter.coin".localized)
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
