import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct ContactBookAddressDuplicateTests {
    private static let rawAddress = "0x1234567890abcdef1234567890abcdef12345678"

    private static let alice = Contact(uid: "1", modifiedAt: 0, name: "Alice", addresses: [
        ContactAddress(blockchainUid: BlockchainType.ethereum.uid, address: rawAddress),
    ])
    private static let bob = Contact(uid: "2", modifiedAt: 0, name: "Bob", addresses: [])

    @Test func matchesCaseInsensitively() {
        let address = ContactAddress(blockchainUid: BlockchainType.ethereum.uid, address: Self.rawAddress.uppercased())
        let duplicate = ContactBookAddressViewModel.duplicate(address: address, contacts: [Self.alice, Self.bob], currentContactUid: Self.bob.uid)
        #expect(duplicate?.uid == Self.alice.uid)
    }

    @Test func matchesWithoutCurrentContact() {
        let address = ContactAddress(blockchainUid: BlockchainType.ethereum.uid, address: Self.rawAddress)
        let duplicate = ContactBookAddressViewModel.duplicate(address: address, contacts: [Self.alice, Self.bob], currentContactUid: nil)
        #expect(duplicate?.uid == Self.alice.uid)
    }

    @Test func excludesCurrentContact() {
        let address = ContactAddress(blockchainUid: BlockchainType.ethereum.uid, address: Self.rawAddress)
        let duplicate = ContactBookAddressViewModel.duplicate(address: address, contacts: [Self.alice, Self.bob], currentContactUid: Self.alice.uid)
        #expect(duplicate == nil)
    }

    @Test func differentBlockchainDoesNotCount() {
        let address = ContactAddress(blockchainUid: BlockchainType.binanceSmartChain.uid, address: Self.rawAddress)
        let duplicate = ContactBookAddressViewModel.duplicate(address: address, contacts: [Self.alice, Self.bob], currentContactUid: nil)
        #expect(duplicate == nil)
    }
}
