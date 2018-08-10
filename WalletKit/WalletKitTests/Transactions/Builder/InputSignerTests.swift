//import XCTest
//import Cuckoo
//import RealmSwift
//@testable import WalletKit
//
//class InputSignerTests: XCTestCase {
//
//    private var mockRealmFactory: MockRealmFactory!
//    private var realm: Realm!
//    private var mockUnspentOutputSelector: MockUnspentOutputSelector!
//    private var mockWalletKitManager: MockWalletKitManager!
//    private var mockHDWallet: MockHDWallet!
//    private var transactionOutputs: [TransactionOutput]!
//    private var transactionBuilder: TransactionBuilder!
//    private var value: Int!
//    private var feeRate: Int!
//    private var fee: Int!
//    private var changeAddress: Address!
//    private var toAddress: Address!
//
//    override func setUp() {
//        super.setUp()
//
//        mockRealmFactory = MockRealmFactory()
//        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
//        try! realm.write { realm.deleteAll() }
//        stub(mockRealmFactory) { mock in
//            when(mock.realm.get).thenReturn(realm)
//        }
//
//        let transaction = TestData.p2pkhTransaction
//
//        // Create private key/address provider for tests
//        let privateKey = HDPrivateKey(privateKey: Data(hex: "6a787b30bd81c8fa5ed09175b5fb08e179cf429ba91ca649dd3317436b7b698e")!, chainCode: Data(), network: TestNet())
//        let publicKeyHash = Data(hex: "7d27dc1a53aaca1195062592e8cdfffa7a79b078")!
//        let ownAddress = Address()
//        ownAddress.publicKey = Data(hex: "03096fa38bfdc7f9baca6562974538ab9894801b69755a7510041bf24c1863848b")!
//        ownAddress.publicKeyHash = publicKeyHash
//        transaction.outputs[0].keyHash = publicKeyHash
//
//        try! realm.write {
//            realm.add(ownAddress, update: true)
//            realm.add(transaction, update: true)
//        }
//
//        transactionOutputs = [transaction.outputs[0]]
//        value = 10782000
//        feeRate = 6
//        fee = 1158
//
//        mockUnspentOutputSelector = MockUnspentOutputSelector()
//        mockHDWallet = MockHDWallet(seed: "sample seed".data(using: .utf8)!, network: TestNet())
//        mockWalletKitManager = MockWalletKitManager()
//
//        stub(mockUnspentOutputSelector) { mock in
//            when(mock.select(value: any(), outputs: any())).thenReturn(transactionOutputs)
//        }
//
//        stub(mockHDWallet) { mock in
//            when(mock.privateKey(index: any(), chain: any())).thenReturn(privateKey)
//        }
//
//        stub(mockWalletKitManager) { mock in
//            when(mock.hdWallet.get).thenReturn(mockHDWallet)
//        }
//
//        transactionBuilder = TransactionBuilder(
//                realmFactory: mockRealmFactory, unspentOutputSelector: mockUnspentOutputSelector, walletKitManager: mockWalletKitManager
//        )
//        changeAddress = TestData.address()
//        toAddress = TestData.address(pubKeyHash: Data(hex: "64d8fbe748c577bb5da29718dae0402b0b5dd523")!)
//    }
//
//    override func tearDown() {
//        mockRealmFactory = nil
//        realm = nil
//        transactionOutputs = nil
//        mockUnspentOutputSelector = nil
//        transactionBuilder = nil
//        changeAddress = nil
//        toAddress = nil
//        mockWalletKitManager = nil
//        mockHDWallet = nil
//        value = nil
//        feeRate = nil
//        fee = nil
//
//        super.tearDown()
//    }
//
//    func testBuildTransaction() {
//        var transaction = Transaction()
//        do {
//            transaction = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changeAddress: changeAddress, toAddress: toAddress)
//        } catch let error {
//            XCTFail(error.localizedDescription)
//        }
//
//        XCTAssertEqual(transaction.inputs.count, 1)
//        XCTAssertEqual(transaction.inputs[0].previousOutput!, transactionOutputs[0])
//        XCTAssertEqual(transaction.outputs.count, 1)
//        XCTAssertEqual(transaction.outputs[0].keyHash, toAddress.publicKeyHash)
//        XCTAssertEqual(transaction.outputs[0].value, 10780842)  // value - fee
//        XCTAssertEqual(transaction.outputs[1].keyHash, changeAddress.publicKeyHash)
//        XCTAssertEqual(transaction.outputs[1].value, transactionOutputs[0].value - value)
//    }
//
//    func testWithoutChangeOutput() {
//        value = value + 10000
//
//        var transaction = Transaction()
//        do {
//            transaction = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changeAddress: changeAddress, toAddress: toAddress)
//        } catch let error {
//            XCTFail(error.localizedDescription)
//        }
//
//        XCTAssertEqual(transaction.inputs.count, 1)
//        XCTAssertEqual(transaction.inputs[0].previousOutput!, transactionOutputs[0])
//        XCTAssertEqual(transaction.outputs.count, 1)
//        XCTAssertEqual(transaction.outputs[0].keyHash, toAddress.publicKeyHash)
//        XCTAssertEqual(transaction.outputs[0].value, value - fee)
//    }
//
//}
