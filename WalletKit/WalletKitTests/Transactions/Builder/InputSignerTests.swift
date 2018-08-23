import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class InputSignerTests: XCTestCase {

    private var realm: Realm!
    private var mockHDWallet: MockHDWallet!
    private var inputSigner: InputSigner!

    private var transaction: Transaction!
    private var ownPubKey: PublicKey!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        realm = mockWalletKit.mockRealm

        // Create private key/address provider for tests
        let privateKey = HDPrivateKey(privateKey: Data(hex: "4ee8efccaa04495d5d3ab0f847952fcff43ffc0459bd87981b6be485b92f8d64")!, chainCode: Data(), network: TestNet())
        let publicKeyHash = Data(hex: "e4de5d630c5cacd7af96418a8f35c411c8ff3c06")!
        ownPubKey = PublicKey()
        ownPubKey.raw = Data(hex: "037d56797fbe9aa506fc263751abf23bb46c9770181a6059096808923f0a64cb15")!
        ownPubKey.keyHash = publicKeyHash

        let previousTransaction = Transaction()
        previousTransaction.reversedHashHex = "f296d7192200cd926369d1a8a88c0339c140149602651c2cc2ed5116368eb79c"
        let previousOutput = TransactionOutput(withValue: 4999900000, index: 0, lockingScript: Data(hex: "76a914e4de5d630c5cacd7af96418a8f35c411c8ff3c0688ac")!, type: .p2pkh, keyHash: publicKeyHash)
        previousOutput.publicKey = ownPubKey
        previousTransaction.outputs.append(previousOutput)

        try! realm.write {
            realm.add(previousTransaction, update: true)
        }

        transaction = Transaction()
        transaction.version = 1
        let payInput = TestData.transactionInput(previousTransaction: previousTransaction, previousOutput: previousOutput, script: Data(), sequence: 4294967295)
        let payOutput = TransactionOutput(withValue: 4999800000, index: 0, lockingScript: Data(hex: "76a914e4de5d630c5cacd7af96418a8f35c411c8ff3c0688ac")!, type: .unknown, keyHash: Data())
        transaction.inputs.append(payInput)
        transaction.outputs.append(payOutput)

        mockHDWallet = mockWalletKit.mockHdWallet

        stub(mockHDWallet) { mock in
            when(mock.privateKey(index: any(), chain: any())).thenReturn(privateKey)
        }

        inputSigner = InputSigner(hdWallet: mockHDWallet)
    }

    override func tearDown() {
        realm = nil
        mockHDWallet = nil
        inputSigner = nil
        transaction = nil

        super.tearDown()
    }

    func testCorrectSignature() {
        var resultSignature = [Data()]
        let signature = Data(hex: "304402201d914e9d229e4b8cbb7c8dee96f4fdd835cabae7e016e0859c5dc95977b697d50220681395971eecd5df3eb36b8f97f0c8b1a6e98dc7d5662f921e0b2fb0694db0f201")!

        do {
            resultSignature = try inputSigner.sigScriptData(transaction: transaction, index: 0)
        } catch let error as InputSigner.SignError {
            print(error)
        } catch {
            print(error)
            XCTFail("Unexpected error")
        }

        XCTAssertEqual(resultSignature[0], signature)
    }

    func testNoPreviousOutput() {
        transaction.inputs[0].previousOutput = nil

        var caught = false
        do {
            let _ = try inputSigner.sigScriptData(transaction: transaction, index: 0)
        } catch let error as InputSigner.SignError {
            caught = true
            XCTAssertEqual(error, InputSigner.SignError.noPreviousOutput)
        } catch {
            XCTFail("Unexpected error")
        }

        XCTAssertEqual(caught, true)
    }

    func testNoPreviousOutputAddress() {
        try! realm.write {
            realm.delete(ownPubKey)
        }

        var caught = false
        do {
            let _ = try inputSigner.sigScriptData(transaction: transaction, index: 0)
        } catch let error as InputSigner.SignError {
            caught = true
            XCTAssertEqual(error, InputSigner.SignError.noPreviousOutputAddress)
        } catch {
            XCTFail("Unexpected error")
        }

        XCTAssertEqual(caught, true)
    }

    func testNoPublicKeyInAddress() {
        try! realm.write {
            ownPubKey.raw = nil
        }

        var caught = false
        do {
            let _ = try inputSigner.sigScriptData(transaction: transaction, index: 0)
        } catch let error as InputSigner.SignError {
            caught = true
            XCTAssertEqual(error, InputSigner.SignError.noPublicKeyInAddress)
        } catch {
            XCTFail("Unexpected error")
        }

        XCTAssertEqual(caught, true)
    }

    func testNoPrivateKey() {
        stub(mockHDWallet) { mock in
            when(mock.privateKey(index: any(), chain: any())).thenThrow(InputSigner.SignError.noPublicKeyInAddress)
        }

        var caught = false
        do {
            let _ = try inputSigner.sigScriptData(transaction: transaction, index: 0)
        } catch let error as InputSigner.SignError {
            caught = true
            XCTAssertEqual(error, InputSigner.SignError.noPrivateKey)
        } catch {
            XCTFail("Unexpected error")
        }

        XCTAssertEqual(caught, true)
    }

}
