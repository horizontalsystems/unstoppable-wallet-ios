import XCTest
import Cuckoo
@testable import WalletKit

class PFromPKHExtractorTests: XCTestCase {
    private var extractor: ScriptExtractor!
    private var scriptConverter: MockScriptConverter!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        scriptConverter = mockWalletKit.mockScriptConverter
        extractor = PFromPKHExtractor()
    }

    override func tearDown() {
        scriptConverter = nil
        extractor = nil

        super.tearDown()
    }

    func testValidExtract() {
        let data = Data(hex: "47304402202fd113a4b302af4487ffd034b37fbce9620031591181549df2f696b79fd9caf0022024b40577c38271ab7ab1112dd092f01ce2664651a718cf20e78f7b131b49a70c0121025cc080f4785724e150b8f76f2efd959f2aaad0038f586c90d88a16ebd73a3e19")!
        let keyData = Data(hex: "025cc080f4785724e150b8f76f2efd959f2aaad0038f586c90d88a16ebd73a3e19")!

        let chunks = [Chunk(scriptData: data, index: 0, payloadRange: 1..<72), Chunk(scriptData: data, index: 72, payloadRange: 73..<106)]

        let script = MockScript(with: data, chunks: chunks)
        stub(script) { mock in
            when(mock.length.get).thenReturn(106)
            when(mock.chunks.get).thenReturn(chunks)
            when(mock.validate(opCodes: any())).thenDoNothing()
        }

        do {
            let test = try extractor.extract(from: script, converter: scriptConverter)
            XCTAssertEqual(test, keyData)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testInvalidLength() {
        let script = MockScript(with: Data(), chunks: [])
        stub(script) { mock in
            when(mock.length.get).thenReturn(2)
            when(mock.chunks.get).thenReturn([])
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

    func testWrongSequence() {
        let data = Data(hex: "47304402202fd113a4b302af4487ffd034b37fbce9620031591181549df2f696b79fd9caf0022024b40577c38271ab7ab1112dd092f01ce2664651a718cf20e78f7b131b49a70c0121025cc080f4785724e150b8f76f2efd959f2aaad0038f586c90d88a16ebd73a3e19")!

        let chunks = [Chunk(scriptData: data, index: 0, payloadRange: 1..<69), Chunk(scriptData: data, index: 72, payloadRange: 73..<104)]
        let script = MockScript(with: data, chunks: chunks)
        stub(script) { mock in
            when(mock.length.get).thenReturn(2)
            when(mock.chunks.get).thenReturn(chunks)
            when(mock.validate(opCodes: any())).thenDoNothing()
        }

        do {
            _ = try extractor.extract(from: script, converter: scriptConverter)
            XCTFail("No Exception Thrown")
        } catch let error as ScriptError {
            XCTAssertEqual(error, ScriptError.wrongSequence)
        } catch {
            XCTFail("Unknown exception thrown")
        }
    }


}
