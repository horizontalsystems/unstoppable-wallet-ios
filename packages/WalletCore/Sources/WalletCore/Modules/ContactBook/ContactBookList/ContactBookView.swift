import MarketKit
import SwiftUI

struct ContactBookView: View {
    @StateObject private var viewModel: ContactBookViewModel
    @Binding private var isPresented: Bool

    private let mode: Mode

    init(mode: Mode, isPresented: Binding<Bool>) {
        self.mode = mode
        _viewModel = StateObject(wrappedValue: ContactBookViewModel(blockchainType: mode.blockchainType))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            Group {
                if viewModel.emptyState == .emptyBook {
                    ThemeView(style: .list) {
                        PlaceholderViewNew(icon: "user", subtitle: "contacts.list.not_found".localized) {
                            if mode.isEdit {
                                ThemeButton(text: "contacts.add_new_contact".localized) {
                                    openNewContact()
                                }
                            }
                        }
                    }
                } else {
                    ThemeView(style: .list) {
                        if viewModel.emptyState == .emptySearch {
                            PlaceholderViewNew(icon: "warning_filled", subtitle: "contacts.list.not_found_search".localized)
                        } else {
                            ThemeList(bottomSpacing: .margin16) {
                                ListForEach(viewModel.items) { item in
                                    row(item: item)
                                }
                            }
                        }
                    }
                    .searchBar(text: $viewModel.filter, prompt: "contacts.list.search_placeholder".localized)
                }
            }
            .navigationTitle("contacts.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }

                if mode.isEdit {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            openNewContact()
                        }) {
                            Image("plus").themeIcon(color: .themeGray)
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            openSettings()
                        }) {
                            Image("manage")
                                .themeIcon(color: .themeGray)
                                .overlay(alignment: .topTrailing) {
                                    if viewModel.showSettingsBadge {
                                        Circle()
                                            .fill(Color.themeLucian)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 4, y: -4)
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private func row(item: ContactBookViewModel.Item) -> some View {
        let cell = Cell(
            middle: {
                MultiText(title: item.name, subtitle: item.subtitle)
            },
            right: {
                Image.disclosureIcon
            },
            action: {
                onTap(item: item)
            }
        )

        if mode.isEdit {
            cell.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    confirmDelete(item: item)
                } label: {
                    Image("trash").renderingMode(.template)
                }
                .tint(.themeLucian)
            }
        } else {
            cell
        }
    }

    private func onTap(item: ContactBookViewModel.Item) {
        switch mode {
        case .edit:
            Coordinator.shared.present { isPresented in
                ContactBookContactView(mode: .exist(uid: item.id, newAddresses: []), isPresented: isPresented)
            }
        case let .select(_, onSelect):
            onSelect(item.address ?? "")
            isPresented = false
        case let .addToContact(address):
            if let oldAddress = viewModel.contactAddress(contactUid: item.id, blockchainUid: address.blockchainUid) {
                confirmReplace(item: item, oldAddress: oldAddress, newAddress: address)
            } else {
                openExisting(item: item, adding: address)
            }
        }
    }

    private func openNewContact() {
        Coordinator.shared.present { isPresented in
            ContactBookContactView(mode: .new, isPresented: isPresented)
        }
    }

    private func openSettings() {
        Coordinator.shared.present { isPresented in
            ContactBookSettingsView(isPresented: isPresented)
        }
    }

    private func openExisting(item: ContactBookViewModel.Item, adding address: ContactAddress) {
        let saved = ContactBookConfirmation()

        Coordinator.shared.present { isPresented in
            ContactBookContactView(mode: .exist(uid: item.id, newAddresses: [address]), isPresented: isPresented) {
                saved.confirmed = true
            }
        } onDismiss: {
            if saved.confirmed {
                isPresented = false
            }
        }
    }

    private func confirmDelete(item: ContactBookViewModel.Item) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.trash, title: "contacts.contact.delete_alert.title".localized),
                    .text(text: "contacts.contact.delete_alert.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .secondary, title: "contacts.contact.delete_alert.delete".localized) {
                            viewModel.delete(contactUid: item.id)
                            isPresented.wrappedValue = false
                        },
                        .init(style: .secondary, mode: .transparent, title: "button.cancel".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ]
            )
        }
    }

    private func confirmReplace(item: ContactBookViewModel.Item, oldAddress: ContactAddress, newAddress: ContactAddress) {
        let blockchainName = viewModel.blockchainName(blockchainUid: newAddress.blockchainUid) ?? ""
        let confirmation = ContactBookConfirmation()

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.warning, title: "alert.warning".localized),
                    .warning(text: "contacts.update_contact.already_has_address".localized(blockchainName, oldAddress.address.shortened, newAddress.address.shortened)),
                    .buttonGroup(.init(buttons: [
                        .init(style: .primary, title: "contacts.update_contact.replace".localized) {
                            confirmation.confirmed = true
                            isPresented.wrappedValue = false
                        },
                        .init(style: .secondary, mode: .transparent, title: "button.cancel".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ]
            )
        } onDismiss: {
            if confirmation.confirmed {
                openExisting(item: item, adding: newAddress)
            }
        }
    }
}

extension ContactBookView {
    enum Mode {
        case edit
        case select(BlockchainType, onSelect: (String) -> Void)
        case addToContact(ContactAddress)

        var blockchainType: BlockchainType? {
            switch self {
            case let .select(blockchainType, _): return blockchainType
            default: return nil
            }
        }

        var isEdit: Bool {
            if case .edit = self {
                return true
            }
            return false
        }
    }
}
