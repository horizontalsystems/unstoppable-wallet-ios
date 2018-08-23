import XCTest
import Cuckoo
@testable import WalletKit

class ScriptConverterTests: XCTestCase {

    private var converter: ScriptConverter!

    override func setUp() {
        super.setUp()

        converter = ScriptConverter()
    }

    override func tearDown() {
        converter = nil

        super.tearDown()
    }

    func testValidDecodeOpCodes() {
        let data = Data(hex: "7602fffca9")!
        let chunks = [Chunk(scriptData: data, index: 0), Chunk(scriptData: data, index: 1, payloadRange: 2..<4), Chunk(scriptData: data, index: 4)]

        do {
            let result = try converter.decode(data: data)
            XCTAssertEqual(result.chunks, chunks)
        } catch {
            XCTFail("Exception thrown!")
        }
    }

    func testValidDecodeInputSignature() {
        let data = Data(hex: "483045022100e2e305079867fd8f277d534a9dc81209cfe12a0efcb31e7778c1fc96686662ce02201dba72ccc146e5bffd68446b9462a933f6b5bb3622bda5a486e21d94ddc4a55d0121030c03b44026546a18a5643a796052692043359fdf6daaf94461d1ca4ec8748afe")!
        let chunks = [Chunk(scriptData: data, index: 0, payloadRange: 1..<73), Chunk(scriptData: data, index: 73, payloadRange: 74..<107)]
        do {
            let result = try converter.decode(data: data)
            XCTAssertEqual(result.chunks, chunks)
        } catch {
            XCTFail("Exception thrown!")
        }
    }

    func testWrongPushDataConvert() {
        do {
            let _ = try converter.decode(data: Data(hex: "02ff")!)
            XCTFail("No wrongPushData!")
        } catch let error as ScriptError {
            XCTAssertEqual(error, ScriptError.wrongScriptLength)
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testValidEncodeOpCodes() {
        let data = Data(hex: "7602fffca9")!
        let chunks = [Chunk(scriptData: data, index: 0), Chunk(scriptData: data, index: 1, payloadRange: 2..<4), Chunk(scriptData: data, index: 4)]

        do {
            let result = converter.encode(script: Script(with: data, chunks: chunks))
            XCTAssertEqual(result, Data(hex: "7602fffca9")!)
        }
    }

}
