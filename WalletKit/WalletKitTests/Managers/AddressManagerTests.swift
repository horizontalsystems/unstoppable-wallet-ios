import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class AddressManagerTests: XCTestCase {

    private var mockWalletKit: MockWalletKit!
    private var mockHDWallet: MockHDWallet!
    private var hdWallet: HDWallet!
    private var manager: AddressManager!

    override func setUp() {
        super.setUp()

        mockWalletKit = MockWalletKit()
        mockHDWallet = mockWalletKit.mockHdWallet
        hdWallet = HDWallet(seed: Data(), network: mockWalletKit.mockNetwork)

        stub(mockWalletKit.mockNetwork) { mock in
            when(mock.pubKeyHash.get).thenReturn(UInt8(0x6f))
        }

        manager = AddressManager(realmFactory: mockWalletKit.mockRealmFactory, hdWallet: mockHDWallet)
    }

    override func tearDown() {
        mockWalletKit = nil
        mockHDWallet = nil
        hdWallet = nil
        manager = nil

        super.tearDown()
    }

    func testChangeAddress() {
        let publicKeys = [
            getPublicKey(withIndex: 0, chain: .internal),
            getPublicKey(withIndex: 0, chain: .external),
            getPublicKey(withIndex: 3, chain: .internal),
            getPublicKey(withIndex: 1, chain: .internal),
            getPublicKey(withIndex: 2, chain: .internal),
            getPublicKey(withIndex: 1, chain: .external)
        ]
        let txOutput = TestData.p2pkhTransaction.outputs[0]

        try! mockWalletKit.realm.write {
            mockWalletKit.realm.add(publicKeys)
            mockWalletKit.realm.add(txOutput)
            txOutput.publicKey = publicKeys[0]
        }

        XCTAssertEqual(try? manager.changeAddress(), publicKeys[3].address)
    }

    func testChangeAddress_NoUnusedPublicKey() {
        let publicKey =  getPublicKey(withIndex: 0, chain: .internal)
        let txOutput = TestData.p2pkhTransaction.outputs[0]

        try! mockWalletKit.realm.write {
            mockWalletKit.realm.add(publicKey)
            mockWalletKit.realm.add(txOutput)
            txOutput.publicKey = publicKey
        }

        let hdPrivKey = try! hdWallet.privateKey(index: 1, chain: .internal)
        let publicKey1 = PublicKey(withIndex: 1, external: false, hdPublicKey: hdPrivKey.publicKey())

        stub(mockHDWallet) { mock in
            when(mock.changePublicKey(index: any())).thenReturn(publicKey1)
        }

        XCTAssertEqual(try? manager.changeAddress(), publicKey1.address)
        verify(mockHDWallet).changePublicKey(index: equal(to: 1))
    }

    func testChangeAddress_NoPublicKey() {
        let hdPrivKey = try! hdWallet.privateKey(index: 0, chain: .internal)
        let publicKey = PublicKey(withIndex: 0, external: false, hdPublicKey: hdPrivKey.publicKey())

        stub(mockHDWallet) { mock in
            when(mock.changePublicKey(index: any())).thenReturn(publicKey)
        }

        XCTAssertEqual(try? manager.changeAddress(), publicKey.address)
        verify(mockHDWallet).changePublicKey(index: equal(to: 0))
    }

    func testChangeAddress_ShouldSaveNewKey() {
        let hdPrivKey = try! hdWallet.privateKey(index: 0, chain: .internal)
        let publicKey = PublicKey(withIndex: 0, external: false, hdPublicKey: hdPrivKey.publicKey())

        stub(mockHDWallet) { mock in
            when(mock.changePublicKey(index: any())).thenReturn(publicKey)
        }

        XCTAssertEqual(try? manager.changeAddress(), publicKey.address)
        let saved = mockWalletKit.realm.objects(PublicKey.self).filter("address = %@", publicKey.address).last
        XCTAssertNotEqual(saved, nil)
    }

    func testReceiveAddress() {
        let publicKeys = [
            getPublicKey(withIndex: 0, chain: .external),
            getPublicKey(withIndex: 0, chain: .internal),
            getPublicKey(withIndex: 3, chain: .external),
            getPublicKey(withIndex: 1, chain: .external),
            getPublicKey(withIndex: 1, chain: .internal),
            getPublicKey(withIndex: 2, chain: .external)
        ]
        let txOutput = TestData.p2pkhTransaction.outputs[0]

        try! mockWalletKit.realm.write {
            mockWalletKit.realm.add(publicKeys)
            mockWalletKit.realm.add(txOutput)
            txOutput.publicKey = publicKeys[0]
        }

        XCTAssertEqual(try? manager.receiveAddress(), publicKeys[3].address)
    }

    func testReceiveAddress_NoUnusedPublicKey() {
        let publicKey =  getPublicKey(withIndex: 0, chain: .external)
        let txOutput = TestData.p2pkhTransaction.outputs[0]

        try! mockWalletKit.realm.write {
            mockWalletKit.realm.add(publicKey)
            mockWalletKit.realm.add(txOutput)
            txOutput.publicKey = publicKey
        }

        let hdPrivKey = try! hdWallet.privateKey(index: 1, chain: .external)
        let publicKey1 = PublicKey(withIndex: 1, external: false, hdPublicKey: hdPrivKey.publicKey())

        stub(mockHDWallet) { mock in
            when(mock.receivePublicKey(index: any())).thenReturn(publicKey1)
        }

        XCTAssertEqual(try? manager.receiveAddress(), publicKey1.address)
        verify(mockHDWallet).receivePublicKey(index: equal(to: 1))
    }

    func testGenerateKeys() {
        let keys = [
            getPublicKey(withIndex: 0, chain: .internal),
            getPublicKey(withIndex: 1, chain: .internal),
            getPublicKey(withIndex: 2, chain: .internal),
            getPublicKey(withIndex: 0, chain: .external),
            getPublicKey(withIndex: 1, chain: .external),
        ]
        let txOutput = TestData.p2pkhTransaction.outputs[0]

        try! mockWalletKit.realm.write {
            mockWalletKit.realm.add([keys[0], keys[1]])
            mockWalletKit.realm.add(txOutput)
            txOutput.publicKey = keys[0]
        }

        stub(mockHDWallet) { mock in
            when(mock.gapLimit.get).thenReturn(2)
            when(mock.changePublicKey(index: equal(to: 2))).thenReturn(keys[2])
            when(mock.receivePublicKey(index: equal(to: 0))).thenReturn(keys[3])
            when(mock.receivePublicKey(index: equal(to: 1))).thenReturn(keys[4])
        }

        try! manager.generateKeys()
        verify(mockHDWallet, times(1)).changePublicKey(index: any())
        verify(mockHDWallet, times(2)).receivePublicKey(index: any())

        let internalKeys = mockWalletKit.realm.objects(PublicKey.self).filter("external = false").sorted(byKeyPath: "index")
        let externalKeys = mockWalletKit.realm.objects(PublicKey.self).filter("external = true").sorted(byKeyPath: "index")

        XCTAssertEqual(internalKeys.count, 3)
        XCTAssertEqual(externalKeys.count, 2)
        XCTAssertEqual(internalKeys[2].address, keys[2].address)
        XCTAssertEqual(externalKeys[0].address, keys[3].address)
        XCTAssertEqual(externalKeys[1].address, keys[4].address)
    }



    private func getPublicKey(withIndex index: Int, chain: HDWallet.Chain) -> PublicKey {
        let hdPrivKey = try! hdWallet.privateKey(index: index, chain: chain)
        return PublicKey(withIndex: index, external: chain == .external, hdPublicKey: hdPrivKey.publicKey())
    }
}
