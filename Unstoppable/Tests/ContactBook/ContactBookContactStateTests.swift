import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct ContactBookContactStateTests {
    private static let address = ContactAddress(blockchainUid: BlockchainType.ethereum.uid, address: "0x1234567890abcdef1234567890abcdef12345678")
    private static let otherAddress = ContactAddress(blockchainUid: BlockchainType.binanceSmartChain.uid, address: "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd")

    private static let alice = Contact(uid: "1", modifiedAt: 0, name: "Alice", addresses: [address])
    private static let bob = Contact(uid: "2", modifiedAt: 0, name: "Bob", addresses: [otherAddress])

    @Test func emptyNameIsIdle() {
        let state = ContactBookContactViewModel.state(name: "   ", addresses: [Self.address], oldContact: nil, allContacts: [Self.alice])
        #expect(state == .idle)
    }

    @Test func noAddressesIsIdle() {
        let state = ContactBookContactViewModel.state(name: "Carol", addresses: [], oldContact: nil, allContacts: [Self.alice])
        #expect(state == .idle)
    }

    @Test func duplicateNameIsCaseInsensitive() {
        let state = ContactBookContactViewModel.state(name: "aLiCe", addresses: [Self.address], oldContact: nil, allContacts: [Self.alice, Self.bob])
        #expect(state == .nameExists)
    }

    @Test func oldNameIsAllowed() {
        let state = ContactBookContactViewModel.state(name: "Alice", addresses: [Self.address, Self.otherAddress], oldContact: Self.alice, allContacts: [Self.alice, Self.bob])
        #expect(state == .updated)
    }

    @Test func renamingToAnotherContactNameIsRejected() {
        let state = ContactBookContactViewModel.state(name: "bob", addresses: [Self.address], oldContact: Self.alice, allContacts: [Self.alice, Self.bob])
        #expect(state == .nameExists)
    }

    @Test func unchangedContactIsIdle() {
        let state = ContactBookContactViewModel.state(name: "Alice", addresses: [Self.address], oldContact: Self.alice, allContacts: [Self.alice, Self.bob])
        #expect(state == .idle)
    }

    @Test func changedContactIsUpdated() {
        let renamed = ContactBookContactViewModel.state(name: "Alice 2", addresses: [Self.address], oldContact: Self.alice, allContacts: [Self.alice, Self.bob])
        #expect(renamed == .updated)

        let newContact = ContactBookContactViewModel.state(name: "Carol", addresses: [Self.address], oldContact: nil, allContacts: [Self.alice, Self.bob])
        #expect(newContact == .updated)
    }
}
