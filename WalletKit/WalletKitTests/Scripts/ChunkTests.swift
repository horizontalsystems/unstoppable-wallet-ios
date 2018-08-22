import XCTest
import Cuckoo
@testable import WalletKit

class ChunkTests: XCTestCase {
    private var data: Data!

    override func setUp() {
        data = Data(hex: "01234567")!
        super.setUp()
    }

    override func tearDown() {
        data = nil
        super.tearDown()
    }

    func testValidOpChunk() {
        let chunk = Chunk(scriptData: data, index: 2)

        XCTAssertNil(chunk.payloadRange)
        XCTAssertNil(chunk.data)

        XCTAssertEqual(chunk.opCode, 0x45)
    }

    func testValidDataChunk() {
        let chunk = Chunk(scriptData: data, index: 0, payloadRange: 1..<3)

        XCTAssertEqual(chunk.data, Data(hex: "2345")!)
    }

    func testInvalidDataChunk() {
        let chunk = Chunk(scriptData: data, index: 0, payloadRange: 1..<6)

        XCTAssertNil(chunk.data)
    }

}
