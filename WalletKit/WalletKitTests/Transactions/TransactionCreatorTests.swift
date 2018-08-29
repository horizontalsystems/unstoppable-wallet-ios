import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionCreatorTests: XCTestCase {

    private var realm: Realm!
    private var mockTransactionBuilder: MockTransactionBuilder!
    private var mockTransactionProcessor: MockTransactionProcessor!
    private var mockTransactionSender: MockTransactionSender!
    private var mockAddressManager: MockAddressManager!

    private var transactionCreator: TransactionCreator!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        realm = mockWalletKit.realm

        mockTransactionBuilder = mockWalletKit.mockTransactionBuilder
        mockTransactionProcessor = mockWalletKit.mockTransactionProcessor
        mockTransactionSender = mockWalletKit.mockTransactionSender
        mockAddressManager = mockWalletKit.mockAddressManager

        stub(mockTransactionBuilder) { mock in
            when(mock.buildTransaction(value: any(), feeRate: any(), senderPay: any(), type: any(), changePubKey: any(), toAddress: any())).thenReturn(TestData.p2pkhTransaction)
        }
        stub(mockTransactionProcessor) { mock in
            when(mock.enqueueRun()).thenDoNothing()
        }
        stub(mockTransactionSender) { mock in
            when(mock.enqueueRun()).thenDoNothing()
        }
        stub(mockAddressManager) { mock in
            when(mock.changePublicKey()).thenReturn(TestData.pubKey())
        }

        transactionCreator = TransactionCreator(realmFactory: mockWalletKit.mockRealmFactory, transactionBuilder: mockTransactionBuilder, transactionProcessor: mockTransactionProcessor, transactionSender: mockTransactionSender, addressManager: mockAddressManager)
    }

    override func tearDown() {
        realm = nil
        mockTransactionBuilder = nil
        mockTransactionProcessor = nil
        mockTransactionSender = nil
        mockAddressManager = nil
        transactionCreator = nil

        super.tearDown()
    }

    func testCreateTransaction() {
        try! transactionCreator.create(to: "Address", value: 1)

        guard let _ = realm.objects(Transaction.self).filter("reversedHashHex = %@", TestData.p2pkhTransaction.reversedHashHex).first else {
            XCTFail("No transaction record!")
            return
        }

        verify(mockTransactionSender).enqueueRun()
        verify(mockTransactionProcessor).enqueueRun()
    }

    func testNoChangeAddress() {
        stub(mockAddressManager) { mock in
            when(mock.changePublicKey()).thenThrow(TransactionBuilder.BuildError.feeMoreThanValue)
        }

        do {
            try transactionCreator.create(to: "Address", value: 1)
            XCTFail("No exception!")
        } catch let error as TransactionCreator.CreationError {
            XCTAssertEqual(error, TransactionCreator.CreationError.noChangeAddress)
        } catch {
            XCTFail("Unexpected exception!")
        }

        verify(mockTransactionSender, never()).enqueueRun()
        verify(mockTransactionProcessor, never()).enqueueRun()
    }

}
