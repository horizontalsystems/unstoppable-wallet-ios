import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class TokenSyncerTests: XCTestCase {
    private var mockStorage: MockICoinStorage!
    private var mockNetworkManager: MockITokenNetworkManager!

    private var syncer: TokenSyncer!

    private let coin1 = Coin(title: "test1", code: "tst1", type: .erc20(address: "test_address1", decimal: 1))
    private let coin2 = Coin(title: "test2", code: "tst3", type: .erc20(address: "test_address2", decimal: 1))
    private let coin3 = Coin(title: "test3", code: "tst3", type: .erc20(address: "test_address3", decimal: 1))

    override func setUp() {
        super.setUp()
        mockStorage = MockICoinStorage()
        mockNetworkManager = MockITokenNetworkManager()

        stub(mockNetworkManager) { mock in
            when(mock.getTokens()).thenReturn(Observable.just([]))
        }

        stub(mockStorage) { mock in
            when(mock.allCoinsObservable()).thenReturn(Observable.just([]))
            when(mock.enabledCoinsObservable()).thenReturn(Observable.just([]))
            when(mock.save(enabledCoins: any())).thenDoNothing()
            when(mock.update(inserted: any(), deleted: any())).thenDoNothing()
            when(mock.clearCoins()).thenDoNothing()
        }

        syncer = TokenSyncer(tokenNetworkManager: mockNetworkManager, storage: mockStorage, async: false)
    }

    override func tearDown() {
        mockStorage = nil

        syncer = nil

        super.tearDown()
    }

    func testSync() {
        syncer.sync()

        verify(mockNetworkManager).getTokens()
        verify(mockStorage).enabledCoinsObservable()
        verify(mockStorage).allCoinsObservable()
    }

    func testAddTokens() {
        stub(mockNetworkManager) { mock in
            when(mock.getTokens()).thenReturn(Observable.just([coin1, coin2, coin3]))
        }
        stub(mockStorage) { mock in
            when(mock.allCoinsObservable()).thenReturn(Observable.just([]))
            when(mock.enabledCoinsObservable()).thenReturn(Observable.just([]))
        }

        syncer.sync()

        verify(mockStorage).update(inserted: equal(to: [coin1, coin2, coin3]), deleted: equal(to: []))
    }

    func testAddExcludeExistTokens() {
        stub(mockNetworkManager) { mock in
            when(mock.getTokens()).thenReturn(Observable.just([coin1, coin2, coin3]))
        }
        stub(mockStorage) { mock in
            when(mock.allCoinsObservable()).thenReturn(Observable.just([coin1, coin2]))
            when(mock.enabledCoinsObservable()).thenReturn(Observable.just([coin1]))
        }

        syncer.sync()

        verify(mockStorage).update(inserted: equal(to: [coin3]), deleted: equal(to: []))
    }

    func testDeleteTokens() {
        stub(mockNetworkManager) { mock in
            when(mock.getTokens()).thenReturn(Observable.just([]))
        }
        stub(mockStorage) { mock in
            when(mock.allCoinsObservable()).thenReturn(Observable.just([coin2]))
            when(mock.enabledCoinsObservable()).thenReturn(Observable.just([coin1]))
        }

        syncer.sync()

        verify(mockStorage).update(inserted: equal(to: []), deleted: equal(to: [coin2]))
    }

    func testDoNothing() {
        stub(mockNetworkManager) { mock in
            when(mock.getTokens()).thenReturn(Observable.just([coin1, coin2, coin3]))
        }
        stub(mockStorage) { mock in
            when(mock.allCoinsObservable()).thenReturn(Observable.just([coin1, coin2, coin3]))
            when(mock.enabledCoinsObservable()).thenReturn(Observable.just([coin1]))
        }

        syncer.sync()

        verify(mockStorage).enabledCoinsObservable()
        verify(mockStorage).allCoinsObservable()

        verifyNoMoreInteractions(mockStorage)
    }

}
