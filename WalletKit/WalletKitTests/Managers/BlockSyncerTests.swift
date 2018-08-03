import XCTest
import Cuckoo
import RealmSwift
import RxSwift
@testable import WalletKit

class BlockSyncerTests: XCTestCase {

    private var mockStorage: MockIStorage!
    private var mockPeerGroup: MockPeerGroup!
    private var blockSyncer: BlockSyncer!

    private var nonSyncedBlocksInsertSubject: PublishSubject<Void>!
    private var peerStatusSubject: PublishSubject<PeerGroup.Status>!

    override func setUp() {
        super.setUp()

        mockStorage = MockIStorage()
        mockPeerGroup = MockPeerGroup()

        nonSyncedBlocksInsertSubject = PublishSubject()
        peerStatusSubject = PublishSubject()

        stub(mockStorage) { mock in
            when(mock.nonSyncedBlocksInsertSubject.get).thenReturn(nonSyncedBlocksInsertSubject)
            when(mock.getNonSyncedBlockHeaderHashes()).thenReturn([])
        }
        stub(mockPeerGroup) { mock in
            when(mock.requestBlocks(headerHashes: any())).thenDoNothing()
            when(mock.statusSubject.get).thenReturn(peerStatusSubject)
        }

        blockSyncer = BlockSyncer(storage: mockStorage, peerGroup: mockPeerGroup, scheduler: MainScheduler.instance)
    }

    override func tearDown() {
        mockStorage = nil
        mockPeerGroup = nil
        blockSyncer = nil

        nonSyncedBlocksInsertSubject = nil
        peerStatusSubject = nil

        super.tearDown()
    }

    func testSync_NoBlocks() {
        peerStatusSubject.onNext(.connected)
        verify(mockPeerGroup, never()).requestBlocks(headerHashes: any())
    }

    func testSync_NonSyncedBlocks() {
        let hash = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!

        stub(mockStorage) { mock in
            when(mock.getNonSyncedBlockHeaderHashes()).thenReturn([hash])
        }

        peerStatusSubject.onNext(.connected)
        verify(mockPeerGroup).requestBlocks(headerHashes: equal(to: [hash]))
    }

    func testSync_OnDisconnect() {
        let hash = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!

        stub(mockStorage) { mock in
            when(mock.getNonSyncedBlockHeaderHashes()).thenReturn([hash])
        }
        peerStatusSubject.onNext(.disconnected)
        verify(mockPeerGroup, never()).requestBlocks(headerHashes: any())
    }

    func testSync_Observe() {
        let hash1 = "000000000000002ca33390dac7a0b98b222b762810f2dda0a00ecf2c1cdf361b".reversedData!
        let hash2 = "000000000000002d7b058a413cda4de7c54ba3ce7836fe75569f908635679afe".reversedData!

        stub(mockStorage) { mock in
            when(mock.getNonSyncedBlockHeaderHashes()).thenReturn([hash1, hash2])
        }

        nonSyncedBlocksInsertSubject.onNext(())

        verify(self.mockPeerGroup).requestBlocks(headerHashes: equal(to: [hash1, hash2]))
    }

}
