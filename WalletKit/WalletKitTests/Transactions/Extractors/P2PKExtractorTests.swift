import XCTest
import Cuckoo
@testable import WalletKit

class P2PKExtractorTests: XCTestCase {

    private var scriptConverter: MockScriptConverter!
    private var extractor: ScriptExtractor!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        scriptConverter = mockWalletKit.mockScriptConverter
        extractor = P2PKExtractor()
    }

    override func tearDown() {
        scriptConverter = nil
        extractor = nil

        super.tearDown()
    }

    func testValidExtract() {
        let pubKey = Data(hex: "030e7061b9fb18571cf2441b2a7ee2419933ddaa423bc178672cd11e87911616d1")!
        let data = Data(hex: "21030e7061b9fb18571cf2441b2a7ee2419933ddaa423bc178672cd11e87911616d1ac")!
        let chunks = [Chunk(scriptData: data, index: 0, payloadRange: 1..<34), Chunk(scriptData: data, index: 34)]

        let script = MockScript(with: data, chunks: chunks)
        stub(script) { mock in
            when(mock.length.get).thenReturn(33)
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
        let data = Data(hex: "21ac")!
        let chunks = [Chunk(scriptData: data, index: 0), Chunk(scriptData: data, index: 1)]

        let script = MockScript(with: data, chunks: chunks)
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

    func testInvalidStartSequence() {
        let data = Data(hex: "f103e061b9")!
        let chunks = [Chunk(scriptData: data, index: 0), Chunk(scriptData: data, index: 1, payloadRange: 2..<5)]

        let script = MockScript(with: data, chunks: chunks)
        stub(script) { mock in
            when(mock.length.get).thenReturn(33)
            when(mock.chunks.get).thenReturn(chunks)
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

    func testInvalidFinishSequence() {
        let data = Data(hex: "03e061b9f1")!
        let chunks = [Chunk(scriptData: data, index: 0, payloadRange: 1..<4), Chunk(scriptData: data, index: 4)]

        let script = MockScript(with: data, chunks: chunks)
        stub(script) { mock in
            when(mock.length.get).thenReturn(33)
            when(mock.chunks.get).thenReturn(chunks)
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
