//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class ERC20InputParserTests: XCTestCase {
//
//    override func setUp() {
//        super.setUp()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//    }
//
//    func testValueAndAddress_functionTransfer() {
//        let response = ERC20InputParser.parse(input: "0xa9059cbb0000000000000000000000005d5724e56ea3cc75352339635960d07c1503f75e00000000000000000000000000000000000000000000003635c9adc5dea00000")
//
//        XCTAssertEqual(Decimal(string: "1000")! * pow(10, 18), response?.value)
//        XCTAssertEqual("0x5d5724e56ea3cc75352339635960d07c1503f75e", response?.to)
//    }
//
//    func testValueAndAddress_functionTransferFrom() {
//        let response = ERC20InputParser.parse(input: "0x23b872dd0000000000000000000000005d5724e56ea3cc75352339635960d07c1503f75e0000000000000000000000005d5724e56ea3cc75352339635960d07c1503f75e00000000000000000000000000000000000000000000003635c9adc5dea00000")
//
//        XCTAssertEqual(Decimal(string: "1000")! * pow(10, 18), response?.value)
//        XCTAssertEqual("0x5d5724e56ea3cc75352339635960d07c1503f75e", response?.to)
//    }
//
//    private func json(from string: String) -> [String: Any] {
//        let jsonData = string.data(using: .utf8)!
//        return (try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any])!
//    }
//
//}
