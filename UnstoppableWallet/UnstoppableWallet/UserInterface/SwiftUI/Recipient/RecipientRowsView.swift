import MarketKit
import SwiftUI

struct RecipientRowsView: View {
    let title: String
    @StateObject var viewModel: RecipientRowsViewModel

    @State private var chooseTypePresented: Bool = false
    @State private var addAddressType: RecipientRowsViewModel.AddAddressType? = nil

    init(title: String, value: String, blockchainType: BlockchainType) {
        self.title = title
        _viewModel = StateObject(wrappedValue: RecipientRowsViewModel(address: value, blockchainType: blockchainType))
    }

    var body: some View {
        ListRow {
            addressView
        }

        if let name = viewModel.name {
            ListRow {
                nameView(name: name)
            }
        }
    }

    @ViewBuilder
    var addressView: some View {
        HStack(spacing: .margin16) {
            Text(title).textSubhead2()

            Spacer()

            Text(viewModel.address)
                .textSubhead1(color: .themeLeah)
                .multilineTextAlignment(.trailing)

            if viewModel.name == nil {
                Button(action: {
                    if viewModel.emptyContacts {
                        addAddressType = .create
                    } else {
                        chooseTypePresented = true
                    }
                }) {
                    Image("user_plus_20").renderingMode(.template)
                }
                .buttonStyle(SecondaryCircleButtonStyle(style: .default))
            }

            Button(action: {
                CopyHelper.copyAndNotify(value: viewModel.address)
            }) {
                Image("copy_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))
        }
        .alert(isPresented: $chooseTypePresented, title: "contacts.add_address.title".localized, viewItems: [
            .init(text: "contacts.add_address.create_new".localized),
            .init(text: "contacts.add_address.add_to_contact".localized),
        ], onTap: { index in
            guard let index else {
                return
            }
            switch index {
            case 0: addAddressType = .create
            case 1: addAddressType = .add
            default: ()
            }
        })
        .sheet(item: $addAddressType) { addType in
            let address = ContactAddress(blockchainUid: viewModel.blockchainType.uid, address: viewModel.address)
            switch addType {
            case .create:
                ContactBookContactView(mode: .add(address), onUpdateContact: nil)
                    .ignoresSafeArea()
            case .add:
                ContactBookView(mode: .addToContact(address), presented: true)
                    .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    func nameView(name: String) -> some View {
        Text("send.confirmation.contact_name".localized).textSubhead2()
        Spacer()
        Text(name)
            .textSubhead1(color: .themeLeah)
            .multilineTextAlignment(.trailing)
    }
}
