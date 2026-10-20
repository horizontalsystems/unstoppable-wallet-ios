import SwiftUI

enum ContactBookModule {
    static func showAddition(contactAddress: ContactAddress, statPage: StatPage, statSection: StatSection? = nil) {
        guard !(Core.shared.contactManager.all?.isEmpty ?? true) else {
            showNewContact(contactAddress: contactAddress, statPage: statPage, statSection: statSection)
            return
        }

        let choice = ContactBookChoice()

        Coordinator.shared.present(type: .alert) { isPresented in
            OptionAlertView(
                title: "contacts.add_address.title".localized,
                viewItems: [
                    AlertViewItem(text: "contacts.add_address.create_new".localized, selected: false),
                    AlertViewItem(text: "contacts.add_address.add_to_contact".localized, selected: false),
                ],
                onSelect: { index in
                    choice.index = index
                },
                isPresented: isPresented
            )
        } onDismiss: {
            switch choice.index {
            case 0:
                showNewContact(contactAddress: contactAddress, statPage: statPage, statSection: statSection)
            case 1:
                stat(page: statPage, section: statSection, event: .open(page: .contactAddToExisting))

                Coordinator.shared.present { isPresented in
                    ContactBookView(mode: .addToContact(contactAddress), isPresented: isPresented)
                }
            default: ()
            }
        }
    }

    private static func showNewContact(contactAddress: ContactAddress, statPage: StatPage, statSection: StatSection?) {
        stat(page: statPage, section: statSection, event: .open(page: .contactNew))

        Coordinator.shared.present { isPresented in
            ContactBookContactView(mode: .add(contactAddress), isPresented: isPresented)
        }
    }
}

final class ContactBookConfirmation {
    var confirmed = false
}

private final class ContactBookChoice {
    var index: Int?
}
