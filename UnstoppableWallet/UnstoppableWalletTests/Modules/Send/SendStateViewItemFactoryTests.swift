//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class SendStateViewItemFactoryTests: XCTestCase {
//    private let coin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
//    private var state = SendState(decimal: 8, inputType: .coin)
//    private var confirmationState = SendState(decimal: 8, inputType: .coin)
//
//    private let address = "address"
//    private let coinValue = CoinValue(coinCode: "BTC", value: 123.45)
//    private let feeCoinValue = CoinValue(coinCode: "BTC", value: 1.234)
//    private let currencyValue = CurrencyValue(currency: Currency(code: "USD", symbol: "$"), value: 987.65)
//    private let feeCurrencyValue = CurrencyValue(currency: Currency(code: "USD", symbol: "$"), value: 9.8765)
//
//    private var factory: SendConfirmationViewItemFactory!
//
//    override func setUp() {
//        super.setUp()
//
//        confirmationState.coinValue = coinValue
//        confirmationState.address = address
//        confirmationState.feeCoinValue = feeCoinValue
//
//        factory = SendConfirmationViewItemFactory()
//    }
//
//    override func tearDown() {
//        factory = nil
//
//        super.tearDown()
//    }
//
//    func testDecimal() {
//        let expectedDecimal = 8
//
//        state.decimal = expectedDecimal
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.decimal, expectedDecimal)
//    }
//
//    func testAmountInfo_CoinType() {
//        state.inputType = .coin
//        state.coinValue = coinValue
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.amountInfo, AmountInfo.coinValue(coinValue: coinValue))
//    }
//
//    func testAmountInfo_CurrencyType() {
//        state.inputType = .currency
//        state.currencyValue = currencyValue
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.amountInfo, AmountInfo.currencyValue(currencyValue: currencyValue))
//    }
//
//    func testAmountRounding_coin() {
//        let expectedValue = Decimal(string: "0.11669944")!
//
//        state.inputType = .coin
//        state.decimal = 8
//        state.coinValue = CoinValue(coinCode: coinValue.coinCode, value: Decimal(string: "0.116699446")!)
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.amountInfo, AmountInfo.coinValue(coinValue: CoinValue(coinCode: coinValue.coinCode, value: expectedValue)))
//    }
//
//    func testAmountRounding_fiat() {
//        let expectedValue = Decimal(string: "0.12")!
//
//        state.inputType = .currency
//        state.decimal = 2
//        state.currencyValue = CurrencyValue(currency: currencyValue.currency, value: Decimal(string: "0.116699446")!)
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.amountInfo, AmountInfo.currencyValue(currencyValue: CurrencyValue(currency: currencyValue.currency, value: expectedValue)))
//    }
//
//    func testSwitchButtonEnabled_True() {
//        state.currencyValue = currencyValue
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertTrue(viewItem.switchButtonEnabled)
//    }
//
//    func testSwitchButtonEnabled_False() {
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertFalse(viewItem.switchButtonEnabled)
//    }
//
//    func testHintInfo_None() {
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertNil(viewItem.hintInfo)
//    }
//
//    func testHintInfo_CoinType() {
//        state.currencyValue = currencyValue
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.hintInfo, HintInfo.amount(amountInfo: .currencyValue(currencyValue: currencyValue)))
//    }
//
//    func testHintInfo_CurrencyType() {
//        state.inputType = .currency
//        state.coinValue = coinValue
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.hintInfo, HintInfo.amount(amountInfo: .coinValue(coinValue: coinValue)))
//    }
//
//    func testHintInfo_Error() {
//        let amountError: AmountInfo = .coinValue(coinValue: coinValue)
//        state.currencyValue = currencyValue
//        state.amountError = amountError
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.hintInfo, HintInfo.error(error: amountError))
//    }
//
//    func testAddressInfo() {
//        let address = "address"
//
//        state.address = address
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.addressInfo, AddressInfo.address(address: address))
//    }
//
//    func testAddressInfo_WithError() {
//        let address = "address"
//        let addressError: AddressError = .invalidAddress
//
//        state.address = address
//        state.addressError = addressError
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertEqual(viewItem.addressInfo, AddressInfo.invalidAddress(address: address, error: addressError))
//    }
//
//    func testFeeInfo_CoinType() {
//        state.inputType = .coin
//        state.feeCoinValue = coinValue
//        state.feeCurrencyValue = currencyValue
//        state.feeError = nil
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        let expectedFeeInfo = FeeInfo(primaryFeeInfo: AmountInfo.coinValue(coinValue: coinValue), secondaryFeeInfo: AmountInfo.currencyValue(currencyValue: currencyValue), error: nil)
//
//        XCTAssertEqual(expectedFeeInfo, viewItem.feeInfo)
//    }
//
//    func testFeeInfo_CurrencyType() {
//        state.inputType = .currency
//        state.feeCoinValue = coinValue
//        state.feeCurrencyValue = currencyValue
//        state.feeError = nil
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        let expectedFeeInfo = FeeInfo(primaryFeeInfo: AmountInfo.currencyValue(currencyValue: currencyValue), secondaryFeeInfo: AmountInfo.coinValue(coinValue: coinValue), error: nil)
//
//        XCTAssertEqual(expectedFeeInfo, viewItem.feeInfo)
//    }
//
//    func testFeeInfo_feeError() {
//        state.inputType = .currency
//        state.feeCoinValue = nil
//        state.feeCurrencyValue = nil
//        let feeError = FeeError.erc20error(erc20CoinCode: "TNT", fee: CoinValue(coinCode: "ETH", value: Decimal(string: "0.04")!))
//        state.feeError = feeError
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        let expectedFeeInfo = FeeInfo(primaryFeeInfo: nil, secondaryFeeInfo: nil, error: feeError)
//
//        XCTAssertEqual(expectedFeeInfo, viewItem.feeInfo)
//    }
//
//    func testSendButtonEnabled_ZeroAmount() {
//        state.coinValue = CoinValue(coinCode: coinValue.coinCode, value: 0)
//        state.address = "address"
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertFalse(viewItem.sendButtonEnabled)
//    }
//
//    func testSendButtonEnabled_AmountError() {
//        state.coinValue = coinValue
//        state.address = "address"
//        state.amountError = .coinValue(coinValue: coinValue)
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertFalse(viewItem.sendButtonEnabled)
//    }
//
//    func testSendButtonEnabled_AddressError() {
//        state.coinValue = coinValue
//        state.address = "address"
//        state.addressError = .invalidAddress
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertFalse(viewItem.sendButtonEnabled)
//    }
//
//    func testSendButtonEnabled_NoAddress() {
//        state.coinValue = coinValue
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertFalse(viewItem.sendButtonEnabled)
//    }
//
//    func testSendButtonEnabled_feeError() {
//        state.coinValue = coinValue
//        state.address = "address"
//        state.feeError = .erc20error(erc20CoinCode: "TNT", fee: CoinValue(coinCode: "ETH", value: 0))
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertFalse(viewItem.sendButtonEnabled)
//    }
//
//    func testSendButtonEnabled_True() {
//        state.coinValue = coinValue
//        state.address = "address"
//
//        let viewItem = factory.viewItem(forState: state, forceRoundDown: false)
//
//        XCTAssertTrue(viewItem.sendButtonEnabled)
//    }
//
//    func testConfirmation_primaryAmountInfo_coinInputType() {
//        confirmationState.inputType = .coin
//
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//
//        let expectedCoinValue = CoinValue(coinCode: coinValue.coinCode, value: -coinValue.value)
//        XCTAssertEqual(viewItem?.primaryAmountInfo, AmountInfo.coinValue(coinValue: expectedCoinValue))
//    }
//
//    func testConfirmation_primaryAmountInfo_currencyInputType() {
//        confirmationState.inputType = .currency
//        confirmationState.currencyValue = currencyValue
//
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//
//        let expectedCurrencyValue = CurrencyValue(currency: currencyValue.currency, value: -currencyValue.value)
//        XCTAssertEqual(viewItem?.primaryAmountInfo, AmountInfo.currencyValue(currencyValue: expectedCurrencyValue))
//    }
//
//    func testConfirmation_secondaryAmountInfo_coinInputType() {
//        confirmationState.inputType = .coin
//        confirmationState.currencyValue = currencyValue
//
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//
//        XCTAssertEqual(viewItem?.secondaryAmountInfo, AmountInfo.currencyValue(currencyValue: currencyValue))
//    }
//
//    func testConfirmation_secondaryAmountInfo_coinInputType_noCurrencyValue() {
//        confirmationState.inputType = .coin
//
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//
//        XCTAssertNil(viewItem?.secondaryAmountInfo)
//    }
//
//    func testConfirmation_secondaryAmountInfo_currencyInputType() {
//        confirmationState.inputType = .currency
//
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//
//        XCTAssertEqual(viewItem?.secondaryAmountInfo, AmountInfo.coinValue(coinValue: coinValue))
//    }
//
//    func testConfirmation_Address() {
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//        XCTAssertEqual(viewItem?.address, address)
//    }
//
//    func testConfirmation_FeeInfo_WithoutCurrencyValue() {
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//        XCTAssertEqual(viewItem?.feeInfo, AmountInfo.coinValue(coinValue: feeCoinValue))
//    }
//
//    func testConfirmation_FeeInfo_WithCurrencyValue() {
//        confirmationState.currencyValue = currencyValue
//        confirmationState.feeCurrencyValue = feeCurrencyValue
//
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//
//        XCTAssertEqual(viewItem?.feeInfo, AmountInfo.currencyValue(currencyValue: feeCurrencyValue))
//    }
//
//    func testConfirmation_TotalInfo_WithoutCurrencyValue() {
//        let totalValue = coinValue.value + feeCoinValue.value
//
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//
//        XCTAssertEqual(viewItem?.totalInfo, AmountInfo.coinValue(coinValue: CoinValue(coinCode: coinValue.coinCode, value: totalValue)))
//    }
//
//    func testConfirmation_totalInfo_erc20_withoutCurrencyValue() {
//        confirmationState.feeCoinValue = CoinValue(coinCode: "ETH", value: 1.234)
//
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//
//        XCTAssertNil(viewItem?.totalInfo)
//    }
//
//    func testConfirmation_TotalInfo_WithCurrencyValue() {
//        confirmationState.currencyValue = currencyValue
//        confirmationState.feeCurrencyValue = feeCurrencyValue
//
//        let totalValue = currencyValue.value + feeCurrencyValue.value
//
//        let viewItem = factory.confirmationViewItem(forState: confirmationState, coin: coin)
//
//        XCTAssertEqual(viewItem?.totalInfo, AmountInfo.currencyValue(currencyValue: CurrencyValue(currency: currencyValue.currency, value: totalValue)))
//    }
//
//}
