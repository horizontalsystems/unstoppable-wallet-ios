import XCTest
import Cuckoo
@testable import WalletKit

class P2SHExtractorTests: XCTestCase {

    private var extractor: ScriptExtractor!
    private var scriptConverter: MockScriptConverter!

    override func setUp() {
        super.setUp()

        scriptConverter = MockScriptConverter()
        extractor = P2SHExtractor()
    }

    override func tearDown() {
        scriptConverter = nil
        extractor = nil

        super.tearDown()
    }

    func testValidExtract() {
        let data = Data(hex: "a9142a02dfd19c9108ad48878a01bfe53deaaf30cca487")!
        let chunks = [Chunk(scriptData: data, index: 0), Chunk(scriptData: data, index: 1, payloadRange: 2..<22), Chunk(scriptData: data, index: 22)]
        let pubKey = Data(hex: "2a02dfd19c9108ad48878a01bfe53deaaf30cca4")!

        let script = MockScript(with: data, chunks: chunks)
        stub(script) { mock in
            when(mock.length.get).thenReturn(23)
            when(mock.chunks.get).thenReturn(chunks)
            when(mock.validate(opCodes: any())).thenDoNothing()
        }

        do {
            let test = try extractor.extract(from: script, converter: scriptConverter)
            XCTAssertEqual(test, pubKey)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testInvalidLength() {
        let script = MockScript(with: Data(), chunks: [])
        stub(script) { mock in
            when(mock.length.get).thenReturn(2)
            when(mock.validate(opCodes: any())).thenDoNothing()
        }

        do {
            _ = try extractor.extract(from: script, converter: scriptConverter)
            XCTFail("No Exception Thrown")
        } catch let error as ScriptError {
            XCTAssertEqual(error, ScriptError.wrongScriptLength)
        } catch {
            XCTFail("Unknown exception thrown")
        }
    }

}
