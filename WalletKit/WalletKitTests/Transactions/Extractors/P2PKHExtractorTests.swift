import XCTest
import Cuckoo
@testable import WalletKit

class P2PKHExtractorTests: XCTestCase {

    private var extractor: ScriptExtractor!
    private var scriptConverter: MockScriptConverter!

    override func setUp() {
        super.setUp()

        scriptConverter = MockScriptConverter()
        extractor = P2PKHExtractor()
    }

    override func tearDown() {
        scriptConverter = nil
        extractor = nil

        super.tearDown()
    }

    func testValidExtract() {
        let data = Data(hex: "76a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac")!
        let chunks = [Chunk(scriptData: data, index: 0), Chunk(scriptData: data, index: 1), Chunk(scriptData: data, index: 2, payloadRange: 3..<23), Chunk(scriptData: data, index: 23), Chunk(scriptData: data, index: 24)]
        let pubKey = Data(hex: "cbc20a7664f2f69e5355aa427045bc15e7c6c772")!

        let script = MockScript(with: data, chunks: chunks)
        stub(script) { mock in
            when(mock.length.get).thenReturn(25)
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
