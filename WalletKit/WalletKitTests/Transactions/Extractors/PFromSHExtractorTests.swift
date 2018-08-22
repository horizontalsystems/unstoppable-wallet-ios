import XCTest
import Cuckoo
@testable import WalletKit

class PFromSHExtractorTests: XCTestCase {

    private var scriptConverter: MockScriptConverter!
    private var extractor: ScriptExtractor!

    private var data: Data!
    private var redeemScriptData: Data!

    private var mockDataLastChunk: MockChunk!
    private var mockRedeemDataLastChunk: MockChunk!
    private var mockScript: MockScript!
    private var mockRedeemScript: MockScript!

    override func setUp() {
        super.setUp()

        data = Data(hex: "9100473044022051c7546ff919248badd1012317066cc0edd3e5f49050ac54ef52b66a8e80e17b02201dd65963551e0dc7d8ce5721fbd3125fa9272a98bad1ed5df91488a462eac1230147512103b4603330291721c0a8e9cae65124a7099ecf0df3b46921d0e30c4220597702cb2102b2ec7de7e811c05aaf8443e3810483d5dbcf671512d9999f9c9772b0ce9da47a52ae")!
        redeemScriptData = Data(hex: "512103b4603330291721c0a8e9cae65124a7099ecf0df3b46921d0e30c4220597702cb2102b2ec7de7e811c05aaf8443e3810483d5dbcf671512d9999f9c9772b0ce9da47a52ae")!

        mockDataLastChunk = MockChunk(scriptData: data, index: 0)
        mockRedeemDataLastChunk = MockChunk(scriptData: redeemScriptData, index: 0)

        mockScript = MockScript(with: Data(), chunks: [])
        mockRedeemScript = MockScript(with: Data(), chunks: [])

        scriptConverter = MockScriptConverter()
        stub(scriptConverter) { mock in
            when(mock.decode(data: any())).thenReturn(mockRedeemScript)
        }

        extractor = PFromSHExtractor()
    }

    override func tearDown() {
        data = nil
        redeemScriptData = nil
        mockRedeemDataLastChunk = nil
        mockDataLastChunk = nil
        mockRedeemScript = nil
        mockScript = nil

        scriptConverter = nil
        extractor = nil

        super.tearDown()
    }

    func testValidExtract() {
        stub(mockDataLastChunk) { mock in
            when(mock.data.get).thenReturn(redeemScriptData)
        }
        stub(mockRedeemDataLastChunk) { mock in
            when(mock.opCode.get).thenReturn(OpCode.checkSig)
            when(mock.data.get).thenReturn(nil)
        }
        stub(mockScript) { mock in
            when(mock.length.get).thenReturn(146)
            when(mock.validate(opCodes: any())).thenDoNothing()
            when(mock.chunks.get).thenReturn([mockDataLastChunk])
        }
        stub(mockRedeemScript) { mock in
            when(mock.length.get).thenReturn(71)
            when(mock.validate(opCodes: any())).thenDoNothing()
            when(mock.chunks.get).thenReturn([mockRedeemDataLastChunk])
        }

        do {
            let test = try extractor.extract(from: mockScript, converter: scriptConverter)
            XCTAssertEqual(test, redeemScriptData)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testWrongScriptLength() {
        stub(mockDataLastChunk) { mock in
            when(mock.data.get).thenReturn(nil)
        }
        stub(mockScript) { mock in
            when(mock.length.get).thenReturn(146)
            when(mock.validate(opCodes: any())).thenDoNothing()
            when(mock.chunks.get).thenReturn([mockDataLastChunk])
        }

        do {
            let _ = try extractor.extract(from: mockScript, converter: scriptConverter)
            XCTFail("No Error found!")
        } catch let error as ScriptError {
            XCTAssertEqual(error, ScriptError.wrongScriptLength)
        } catch {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testWrongRedeemScript() {
        stub(mockDataLastChunk) { mock in
            when(mock.data.get).thenReturn(redeemScriptData)
        }
        stub(mockScript) { mock in
            when(mock.length.get).thenReturn(146)
            when(mock.validate(opCodes: any())).thenDoNothing()
            when(mock.chunks.get).thenReturn([mockDataLastChunk])
        }
        stub(mockRedeemScript) { mock in
            when(mock.length.get).thenReturn(71)
            when(mock.validate(opCodes: any())).thenDoNothing()
            when(mock.chunks.get).thenReturn([])
        }

        do {
            let _ = try extractor.extract(from: mockScript, converter: scriptConverter)
            XCTFail("No Error found!")
        } catch let error as ScriptError {
            XCTAssertEqual(error, ScriptError.wrongSequence)
        } catch {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testValidRedeemWithIfScript() {
        stub(mockDataLastChunk) { mock in
            when(mock.data.get).thenReturn(redeemScriptData)
        }
        stub(mockRedeemDataLastChunk) { mock in
            when(mock.opCode.get).thenReturn(OpCode.checkSigVerify)
            when(mock.data.get).thenReturn(nil)
        }
        stub(mockScript) { mock in
            when(mock.length.get).thenReturn(146)
            when(mock.validate(opCodes: any())).thenDoNothing()
            when(mock.chunks.get).thenReturn([mockDataLastChunk])
        }
        let mockRedeemDataIFChunk = MockChunk(scriptData: redeemScriptData, index: 0)
        stub(mockRedeemDataIFChunk) { mock in
            when(mock.opCode.get).thenReturn(OpCode.endIf)
            when(mock.data.get).thenReturn(nil)
        }

        stub(mockRedeemScript) { mock in
            when(mock.length.get).thenReturn(71)
            when(mock.validate(opCodes: any())).thenDoNothing()
            when(mock.chunks.get).thenReturn([mockRedeemDataLastChunk, mockRedeemDataIFChunk])
        }

        do {
            let test = try extractor.extract(from: mockScript, converter: scriptConverter)
            XCTAssertEqual(test, redeemScriptData)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testWrongRedeemLastCodeScript() {
        stub(mockDataLastChunk) { mock in
            when(mock.data.get).thenReturn(redeemScriptData)
        }
        stub(mockRedeemDataLastChunk) { mock in
            when(mock.opCode.get).thenReturn(OpCode.dup)
            when(mock.data.get).thenReturn(nil)
        }
        stub(mockScript) { mock in
            when(mock.length.get).thenReturn(146)
            when(mock.validate(opCodes: any())).thenDoNothing()
            when(mock.chunks.get).thenReturn([mockDataLastChunk])
        }
        stub(mockRedeemScript) { mock in
            when(mock.length.get).thenReturn(71)
            when(mock.validate(opCodes: any())).thenDoNothing()
            when(mock.chunks.get).thenReturn([])
        }

        do {
            let _ = try extractor.extract(from: mockScript, converter: scriptConverter)
            XCTFail("No Error found!")
        } catch let error as ScriptError {
            XCTAssertEqual(error, ScriptError.wrongSequence)
        } catch {
            XCTFail("\(error) Exception Thrown")
        }
    }

}
