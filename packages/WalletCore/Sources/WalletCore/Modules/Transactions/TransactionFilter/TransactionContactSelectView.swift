import Kingfisher
import MarketKit
import SwiftUI

struct TransactionContactSelectView: View {
    @ObservedObject var viewModel: TransactionContactSelectViewModel
    @Binding var isPresented: Bool

    @State private var searchText: String = ""

    init(transactionFilterViewModel: TransactionFilterViewModel, isPresented: Binding<Bool>) {
        _viewModel = ObservedObject(wrappedValue: TransactionContactSelectViewModel(transactionFilterViewModel: transactionFilterViewModel))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeView {
            VStack(spacing: .margin12) {
                Text("transaction_filter.description".localized(
                    viewModel.allowedBlockchainsForContact.map(\.name).joined(separator: ", ")
                ))
                .themeSubhead2()
                .padding(.padding16)

                if !viewModel.contacts.isEmpty {
                    ScrollableThemeView {
                        ListSection {
                            Cell(
                                left: { ThemeImage("paper_contract", size: .iconSize24) },
                                middle: { ThemeText("transaction_filter.all_contacts".localized, style: .headline2) },
                                right: {
                                    if viewModel.currentContact == nil {
                                        Image.checkIcon
                                    }
                                },
                                action: {
                                    viewModel.set(currentContact: nil)
                                    isPresented = false
                                }
                            )

                            ForEach(searchResults, id: \.self) { contact in
                                Cell(
                                    left: { ThemeImage("user", size: .iconSize24) },
                                    middle: { ThemeText(contact.name, style: .headline2) },
                                    right: {
                                        if viewModel.currentContact == contact {
                                            Image.checkIcon
                                        }
                                    },
                                    action: {
                                        viewModel.set(currentContact: contact)
                                        isPresented = false
                                    }
                                )
                            }
                        }
                        .themeListStyle(.transparent)
                        .padding(.bottom, .margin32)
                    }
                } else {
                    PlaceholderViewNew(icon: "not_found_48", subtitle: "no suitable contacts".localized)
                }
            }
            .navigationTitle("contacts.title".localized)
            .searchBar(text: $searchText, prompt: "placeholder.search".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
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
