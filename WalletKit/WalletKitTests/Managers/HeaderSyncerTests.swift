import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HeaderSyncerTests: XCTestCase {

    private var mockStorage: MockIStorage!
    private var mockPeerGroup: MockPeerGroup!
    private var headerSyncer: HeaderSyncer!

    private var realm: Realm!
    private var preCheckpointBlock: Block!
    private var checkpointBlock: Block!

    override func setUp() {
        super.setUp()

        mockStorage = MockIStorage()
        mockPeerGroup = MockPeerGroup()
        headerSyncer = HeaderSyncer(storage: mockStorage, peerGroup: mockPeerGroup)

        preCheckpointBlock = BlockFactory.shared.block(withHeader: TestHelper.preCheckpointBlockHeader, height: TestHelper.preCheckpointBlockHeight)
        checkpointBlock = BlockFactory.shared.block(withHeader: TestHelper.checkpointBlockHeader, previousBlock: preCheckpointBlock)

        stub(mockStorage) { mock in
            when(mock.getFirstBlockInChain()).thenReturn(checkpointBlock)
            when(mock.getLastBlockInChain(afterBlock: equal(to: checkpointBlock))).thenReturn(nil)
            when(mock.getBlockInChain(withHeight: checkpointBlock.height + 1)).thenReturn(nil)
        }
        stub(mockPeerGroup) { mock in
            when(mock.requestHeaders(headerHashes: any())).thenDoNothing()
        }
    }

    override func tearDown() {
        mockStorage = nil
        mockPeerGroup = nil
        headerSyncer = nil

        realm = nil
        preCheckpointBlock = nil
        checkpointBlock = nil

        super.tearDown()
    }

    func testSync_NoCheckpointBlock() {
        stub(mockStorage) { mock in
            when(mock.getFirstBlockInChain()).thenReturn(nil)
        }

        var caught = false

        do {
            try headerSyncer.sync()
        } catch let error as HeaderSyncer.SyncError {
            caught = true
            XCTAssertEqual(error, HeaderSyncer.SyncError.noCheckpointBlock)
        } catch {
            XCTFail("Unknown exception thrown")
        }

        verifyNoMoreInteractions(mockPeerGroup)
        XCTAssertTrue(caught, "noCheckpointBlock exception not thrown")
    }

    func testSync_OnlyCheckpointBlock() {
        try! headerSyncer.sync()
        verify(mockPeerGroup).requestHeaders(headerHashes: equal(to: [checkpointBlock.headerHash]))
    }

    func testSync_99LastBlocks() {
        let firstHeaderHash = "0000000000012d1d8525ce2db0abdb3617203ccd8485ecad81e37e5a228f7036".reversedData!
        let lastHeaderHash = "000000000005c9a9d1e992f46bf0c0400a45feeb39d634e0a3cdde08c3b9f512".reversedData!

        let firstBlock = Block()
        firstBlock.headerHash = firstHeaderHash
        let lastBlock = Block()
        lastBlock.headerHash = lastHeaderHash
        lastBlock.height = checkpointBlock.height + 99

        stub(mockStorage) { mock in
            when(mock.getLastBlockInChain(afterBlock: equal(to: checkpointBlock))).thenReturn(lastBlock)
            when(mock.getBlockInChain(withHeight: lastBlock.height - 99 + 1)).thenReturn(firstBlock)
        }

        try! headerSyncer.sync()
        verify(mockPeerGroup).requestHeaders(headerHashes: equal(to: [lastHeaderHash, checkpointBlock.headerHash]))
    }

    func testSync_100LastBlocks() {
        let firstHeaderHash = "0000000000012d1d8525ce2db0abdb3617203ccd8485ecad81e37e5a228f7036".reversedData!
        let lastHeaderHash = "000000000005c9a9d1e992f46bf0c0400a45feeb39d634e0a3cdde08c3b9f512".reversedData!

        let firstBlock = Block()
        firstBlock.headerHash = firstHeaderHash
        let lastBlock = Block()
        lastBlock.headerHash = lastHeaderHash
        lastBlock.height = checkpointBlock.height + 100

        stub(mockStorage) { mock in
            when(mock.getLastBlockInChain(afterBlock: equal(to: checkpointBlock))).thenReturn(lastBlock)
            when(mock.getBlockInChain(withHeight: lastBlock.height - 100 + 1)).thenReturn(firstBlock)
        }

        try! headerSyncer.sync()
        verify(mockPeerGroup).requestHeaders(headerHashes: equal(to: [lastHeaderHash, firstHeaderHash]))
    }

}
