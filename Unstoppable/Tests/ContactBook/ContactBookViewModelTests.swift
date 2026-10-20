import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct ContactBookViewModelTests {
    private static let ethAddress = "0x1234567890abcdef1234567890abcdef12345678"
    private static let bscAddress = "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"

    private static func contact(uid: String, name: String, addresses: [ContactAddress]) -> Contact {
        Contact(uid: uid, modifiedAt: 0, name: name, addresses: addresses)
    }

    private static let contacts: [Contact] = [
        contact(uid: "1", name: "Charlie", addresses: [ContactAddress(blockchainUid: BlockchainType.ethereum.uid, address: ethAddress)]),
        contact(uid: "2", name: "alice", addresses: [ContactAddress(blockchainUid: BlockchainType.binanceSmartChain.uid, address: bscAddress)]),
        contact(uid: "3", name: "Bob", addresses: [
            ContactAddress(blockchainUid: BlockchainType.ethereum.uid, address: ethAddress),
            ContactAddress(blockchainUid: BlockchainType.binanceSmartChain.uid, address: bscAddress),
        ]),
    ]

    @Test func sortsByName() {
        let items = ContactBookViewModel.items(contacts: Self.contacts, filter: "", blockchainType: nil)
        #expect(items.map(\.name) == ["Bob", "Charlie", "alice"])
    }

    @Test func filtersCaseInsensitively() {
        let items = ContactBookViewModel.items(contacts: Self.contacts, filter: "ALI", blockchainType: nil)
        #expect(items.map(\.id) == ["2"])

        let lowercased = ContactBookViewModel.items(contacts: Self.contacts, filter: "charl", blockchainType: nil)
        #expect(lowercased.map(\.id) == ["1"])
    }

    @Test func editModeShowsAddressCount() {
        let items = ContactBookViewModel.items(contacts: Self.contacts, filter: "bob", blockchainType: nil)
        #expect(items.count == 1)
        #expect(items.first?.subtitle == "contacts.list.addresses_count".localized(2))
        #expect(items.first?.address == nil)
    }

    @Test func selectModeDropsContactsWithoutAddressOnChain() {
        let items = ContactBookViewModel.items(contacts: Self.contacts, filter: "", blockchainType: .ethereum)
        #expect(items.map(\.id) == ["3", "1"])
    }

    @Test func selectModeShowsShortenedAddress() {
        let items = ContactBookViewModel.items(contacts: Self.contacts, filter: "", blockchainType: .binanceSmartChain)
        #expect(items.map(\.id) == ["3", "2"])
        #expect(items.allSatisfy { $0.address == Self.bscAddress })
        #expect(items.allSatisfy { $0.subtitle == Self.bscAddress.shortened })
    }

    @Test func noMatchesGiveEmptyList() {
        let items = ContactBookViewModel.items(contacts: Self.contacts, filter: "zed", blockchainType: nil)
        #expect(items.isEmpty)
    }
}
