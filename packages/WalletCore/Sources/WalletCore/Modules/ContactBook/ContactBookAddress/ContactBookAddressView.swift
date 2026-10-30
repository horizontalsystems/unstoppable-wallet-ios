import MarketKit
import SwiftUI

struct ContactBookAddressView: View {
    @StateObject private var viewModel: ContactBookAddressViewModel
    @Binding private var isPresented: Bool

    private let onSave: (ContactAddress) -> Void
    private let onDelete: (ContactAddress) -> Void

    init(
        contactUid: String?,
        mode: ContactBookAddressViewModel.Mode,
        blockchain: Blockchain,
        isPresented: Binding<Bool>,
        onSave: @escaping (ContactAddress) -> Void,
        onDelete: @escaping (ContactAddress) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: ContactBookAddressViewModel(contactUid: contactUid, mode: mode, blockchain: blockchain))
        _isPresented = isPresented
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: .margin24) {
                            ListSection {
                                blockchainRow(editable: !viewModel.isEdit)
                            }

                            VStack(spacing: .margin12) {
                                AddressViewNew(
                                    initial: .init(blockchainType: viewModel.selectedBlockchain.type, showContacts: false),
                                    text: $viewModel.text,
                                    result: $viewModel.addressResult,
                                    parserFilter: nil,
                                    borderColor: Binding(get: { borderColor }, set: { _ in })
                                )
                                .id(viewModel.selectedBlockchain.uid)

                                if case let .invalid(caution?) = viewModel.state {
                                    HighlightedTextView(caution: caution)
                                }
                            }

                            if viewModel.isEdit {
                                ListSection {
                                    Cell(
                                        left: { ThemeImage("trash", size: .iconSize24, colorStyle: .red) },
                                        middle: { ThemeText("contacts.contact.address.delete_address".localized, style: .headline2, colorStyle: .red) },
                                        action: {
                                            confirmDelete()
                                        }
                                    )
                                }
                            }
                        }
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                } bottomContent: {
                    if !viewModel.isEdit {
                        ThemeButton(text: "button.done".localized) {
                            save()
                        }
                        .disabled(!viewModel.saveEnabled)
                    }
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        onClose()
                    }) {
                        Image("close")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        save()
                    }) {
                        Image("check")
                    }
                    .modifier(ConfirmationButtonStyle())
                    .disabled(!viewModel.saveEnabled)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.hasChanges)
    }

    @ViewBuilder private func blockchainRow(editable: Bool) -> some View {
        Cell(
            middle: { ThemeText("contacts.contact.address.blockchain".localized, style: .headline2) },
            right: {
                let value = ThemeText(viewModel.selectedBlockchain.name, style: .subheadSB, colorStyle: editable ? .primary : .secondary)

                if editable {
                    value.arrow(style: .dropdown)
                } else {
                    value
                }
            },
            action: editable ? { presentBlockchainSelect() } : nil
        )
    }

    private var borderColor: Color {
        if case .invalid = viewModel.state {
            return .themeLucian
        }

        return .themeBlade
    }

    private func presentBlockchainSelect() {
        Coordinator.shared.present { isPresented in
            ContactBookBlockchainSelectView(
                blockchains: viewModel.blockchains,
                selected: viewModel.selectedBlockchain,
                isPresented: isPresented
            ) { blockchain in
                viewModel.selectedBlockchain = blockchain
            }
        }
    }

    private func save() {
        if let address = viewModel.contactAddress {
            onSave(address)
            isPresented = false
        }
    }

    private func onClose() {
        guard viewModel.hasChanges else {
            isPresented = false
            return
        }

        let confirmation = ContactBookConfirmation()

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.warning, title: "alert.warning".localized),
                    .warning(text: "contacts.contact.dismiss_changes.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .secondary, title: "contacts.contact.dismiss_changes.discard_changes".localized) {
                            confirmation.confirmed = true
                            isPresented.wrappedValue = false
                        },
                        .init(style: .secondary, mode: .transparent, title: "contacts.contact.dismiss_changes.keep_editing".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ]
            )
        } onDismiss: {
            if confirmation.confirmed {
                isPresented = false
            }
        }
    }

    private func confirmDelete() {
        guard let initialAddress = viewModel.initialAddress else {
            return
        }

        let confirmation = ContactBookConfirmation()

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.trash, title: "contacts.add_address.delete_alert.title".localized),
                    .text(text: "contacts.add_address.delete_alert.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .secondary, title: "contacts.add_address.delete_alert.delete".localized) {
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
                onDelete(initialAddress)
                isPresented = false
            }
        }
    }
}
