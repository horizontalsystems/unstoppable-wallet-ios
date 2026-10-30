import MarketKit
import SwiftUI

struct ContactBookContactView: View {
    @StateObject private var viewModel: ContactBookContactViewModel
    @Binding private var isPresented: Bool

    private let onSave: (() -> Void)?

    @FocusState private var isNameFocused: Bool

    init(mode: ContactBookContactViewModel.Mode, isPresented: Binding<Bool>, onSave: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ContactBookContactViewModel(mode: mode))
        _isPresented = isPresented
        self.onSave = onSave
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                VStack(spacing: .margin24) {
                    InputTextRow(borderColor: Binding(get: { nameBorderColor }, set: { _ in })) {
                        InputTextView(
                            placeholder: "contacts.contact.name.placeholder".localized,
                            text: $viewModel.name
                        )
                        .autocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isNameFocused)
                    }
                    .modifier(CautionPrompt(cautionState: Binding(get: { nameCautionState }, set: { _ in })))

                    if !viewModel.addressItems.isEmpty {
                        ListSection {
                            ForEach(viewModel.addressItems) { item in
                                Cell(
                                    left: { BlockchainIcon(blockchain: item.blockchain) },
                                    middle: { MultiText(title: item.blockchain.name, subtitle: item.address) },
                                    right: { ThemeImage("pen", size: .iconSize20, colorStyle: item.edited ? .yellow : .secondary) },
                                    action: {
                                        openAddress(item: item)
                                    }
                                )
                            }
                        }
                    }

                    if !viewModel.allBlockchainsUsed || viewModel.isExisting {
                        ListSection {
                            if !viewModel.allBlockchainsUsed {
                                Cell(
                                    left: { ThemeImage("plus", size: .iconSize24, colorStyle: .yellow) },
                                    middle: { ThemeText("contacts.contact.add_address".localized, style: .headline2, colorStyle: .yellow) },
                                    action: {
                                        openAddress(item: nil)
                                    }
                                )
                            }

                            if viewModel.isExisting {
                                Cell(
                                    left: { ThemeImage("trash", size: .iconSize24, colorStyle: .red) },
                                    middle: { ThemeText("contacts.contact.delete".localized, style: .headline2, colorStyle: .red) },
                                    action: {
                                        confirmDelete()
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .onTapGesture {
                isNameFocused = false
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

    private var nameBorderColor: Color {
        viewModel.state == .nameExists ? .themeLucian : .themeBlade
    }

    private var nameCautionState: CautionState {
        guard viewModel.state == .nameExists else {
            return .none
        }

        return .caution(Caution(text: "contacts.contact.update.error.name_already_exist".localized, type: .error))
    }

    private func save() {
        do {
            try viewModel.save()
            onSave?()
            isPresented = false
        } catch {
            HudHelper.instance.show(banner: .error(string: error.localizedDescription))
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
        let confirmation = ContactBookConfirmation()

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.trash, title: "contacts.contact.delete_alert.title".localized),
                    .text(text: "contacts.contact.delete_alert.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .secondary, title: "contacts.contact.delete_alert.delete".localized) {
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
                delete()
            }
        }
    }

    private func delete() {
        do {
            try viewModel.delete()
            onSave?()
            isPresented = false
        } catch {
            HudHelper.instance.show(banner: .error(string: error.localizedDescription))
        }
    }

    private func openAddress(item: ContactBookContactViewModel.AddressItem?) {
        let mode: ContactBookAddressViewModel.Mode
        let blockchain: Blockchain

        if let item {
            mode = .edit(ContactAddress(blockchainUid: item.blockchain.uid, address: item.address))
            blockchain = item.blockchain
        } else {
            guard let firstUnusedBlockchain = viewModel.firstUnusedBlockchain else {
                return
            }

            mode = .create(existingAddresses: viewModel.addresses)
            blockchain = firstUnusedBlockchain
        }

        Coordinator.shared.present { isPresented in
            ContactBookAddressView(
                contactUid: viewModel.contactUid,
                mode: mode,
                blockchain: blockchain,
                isPresented: isPresented,
                onSave: { address in
                    viewModel.set(address: address)
                },
                onDelete: { address in
                    viewModel.remove(address: address)
                }
            )
        }
    }
}
