//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class AddressParserTests: XCTestCase {
//
//    private var addressParser: AddressParser!
//
//    override func setUp() {
//        super.setUp()
//    }
//
//    override func tearDown() {
//        addressParser = nil
//
//        super.tearDown()
//    }
//
//    func testParseBitcoinPaymentAddress() {
//        addressParser = AddressParser(validScheme: "bitcoin", removeScheme: true)
//
//        var paymentData = AddressData(address: "address_data")
//        checkAddressData(addressParser: addressParser, paymentAddress: "address_data", paymentData: paymentData)
//
//        // Check bitcoin addresses parsing with drop scheme if it's valid
//        paymentData = AddressData(address: "address_data")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoin:address_data", paymentData: paymentData)
//
//        // invalid scheme - need to keep scheme
//        paymentData = AddressData(address: "bitcoincash:address_data")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoincash:address_data", paymentData: paymentData)
//
//        // check parameters
//        paymentData = AddressData(address: "address_data", version: "1.0")
//        checkAddressData(addressParser: addressParser, paymentAddress: "address_data;version=1.0", paymentData: paymentData)
//
//        paymentData = AddressData(address: "address_data", version: "1.0", label: "test")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoin:address_data;version=1.0?label=test", paymentData: paymentData)
//
//        paymentData = AddressData(address: "address_data", amount: 0.01)
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoin:address_data?amount=0.01", paymentData: paymentData)
//
//        paymentData = AddressData(address: "address_data", amount: 0.01, label: "test_sender")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoin:address_data?amount=0.01&label=test_sender", paymentData: paymentData)
//
//        paymentData = AddressData(address: "address_data", parameters: ["custom":"any"])
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoin:address_data?custom=any", paymentData: paymentData)
//
//        paymentData = AddressData(address: "175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W", amount: 50, label: "Luke-Jr", message: "Donation for project xyz")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation%20for%20project%20xyz", paymentData: paymentData)
//    }
//
//    func testParseBitcoinCashPaymentAddress() {
//        addressParser = AddressParser(validScheme: "bitcoincash", removeScheme: false)
//
//        var paymentData = AddressData(address: "address_data")
//        checkAddressData(addressParser: addressParser, paymentAddress: "address_data", paymentData: paymentData)
//
//        // Check bitcoincash addresses parsing with keep scheme if it's valid
//        paymentData = AddressData(address: "bitcoincash:address_data")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoincash:address_data", paymentData: paymentData)
//
//        // invalid scheme - need to leave scheme
//        paymentData = AddressData(address: "bitcoin:address_data")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoin:address_data", paymentData: paymentData)
//
//        // check parameters
//        paymentData = AddressData(address: "address_data", version: "1.0")
//        checkAddressData(addressParser: addressParser, paymentAddress: "address_data;version=1.0", paymentData: paymentData)
//
//        paymentData = AddressData(address: "bitcoincash:address_data", version: "1.0", label: "test")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoincash:address_data;version=1.0?label=test", paymentData: paymentData)
//
//        paymentData = AddressData(address: "bitcoincash:address_data", amount: 0.01)
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoincash:address_data?amount=0.01", paymentData: paymentData)
//
//        paymentData = AddressData(address: "bitcoincash:address_data", amount: 0.01, label: "test_sender")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoincash:address_data?amount=0.01&label=test_sender", paymentData: paymentData)
//
//        paymentData = AddressData(address: "bitcoincash:address_data", parameters: ["custom":"any"])
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoincash:address_data?custom=any", paymentData: paymentData)
//    }
//
//    func testParseEthereumPaymentAddress() {
//        addressParser = AddressParser(validScheme: "ethereum", removeScheme: true)
//
//        var paymentData = AddressData(address: "address_data")
//        checkAddressData(addressParser: addressParser, paymentAddress: "address_data", paymentData: paymentData)
//
//        // Check bitcoin addresses parsing with drop scheme if it's valid
//        paymentData = AddressData(address: "address_data")
//        checkAddressData(addressParser: addressParser, paymentAddress: "ethereum:address_data", paymentData: paymentData)
//
//        // invalid scheme - need to keep scheme
//        paymentData = AddressData(address: "bitcoincash:address_data")
//        checkAddressData(addressParser: addressParser, paymentAddress: "bitcoincash:address_data", paymentData: paymentData)
//
//        // check parameters
//        paymentData = AddressData(address: "address_data", version: "1.0")
//        checkAddressData(addressParser: addressParser, paymentAddress: "address_data;version=1.0", paymentData: paymentData)
//
//        paymentData = AddressData(address: "address_data", version: "1.0", label: "test")
//        checkAddressData(addressParser: addressParser, paymentAddress: "ethereum:address_data;version=1.0?label=test", paymentData: paymentData)
//
//        paymentData = AddressData(address: "address_data", amount: 0.01)
//        checkAddressData(addressParser: addressParser, paymentAddress: "ethereum:address_data?amount=0.01", paymentData: paymentData)
//
//        paymentData = AddressData(address: "address_data", amount: 0.01, label: "test_sender")
//        checkAddressData(addressParser: addressParser, paymentAddress: "ethereum:address_data?amount=0.01&label=test_sender", paymentData: paymentData)
//
//        paymentData = AddressData(address: "address_data", parameters: ["custom":"any"])
//        checkAddressData(addressParser: addressParser, paymentAddress: "ethereum:address_data?custom=any", paymentData: paymentData)
//
//        paymentData = AddressData(address: "175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W", amount: 50, label: "Luke-Jr", message: "Donation for project xyz")
//        checkAddressData(addressParser: addressParser, paymentAddress: "ethereum:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation%20for%20project%20xyz", paymentData: paymentData)
//    }
//
//    private func checkAddressData(addressParser: AddressParser, paymentAddress: String, paymentData: AddressData) {
//        let bitcoinPaymentData = addressParser.parse(paymentAddress: paymentAddress)
//        XCTAssertEqual(bitcoinPaymentData, paymentData)
//    }
//
//}
