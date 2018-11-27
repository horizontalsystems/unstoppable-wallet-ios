import XCTest
import Cuckoo
@testable import Bank_Dev_T

class SendStateViewItemFactoryTests: XCTestCase {
    private var state = SendState(inputType: .coin)
    private var confirmationState = SendState(inputType: .coin)

    private let address = "address"
    private let coinValue = CoinValue(coin: "BTC", value: 123.45)
    private let feeCoinValue = CoinValue(coin: "BTC", value: 1.234)
    private let currencyValue = CurrencyValue(currency: Currency(code: "USD", symbol: "$"), value: 987.65)
    private let feeCurrencyValue = CurrencyValue(currency: Currency(code: "USD", symbol: "$"), value: 9.8765)

    private var factory: SendStateViewItemFactory!

    override func setUp() {
        super.setUp()

        confirmationState.coinValue = coinValue
        confirmationState.address = address
        confirmationState.feeCoinValue = feeCoinValue

        factory = SendStateViewItemFactory()
    }

    override func tearDown() {
        factory = nil

        super.tearDown()
    }

    func testAmountInfo_CoinType() {
        state.inputType = .coin
        state.coinValue = coinValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.amountInfo, AmountInfo.coinValue(coinValue: coinValue))
    }

    func testAmountInfo_CurrencyType() {
        state.inputType = .currency
        state.currencyValue = currencyValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.amountInfo, AmountInfo.currencyValue(currencyValue: currencyValue))
    }

    func testSwitchButtonEnabled_True() {
        state.currencyValue = currencyValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertTrue(viewItem.switchButtonEnabled)
    }

    func testSwitchButtonEnabled_False() {
        let viewItem = factory.viewItem(forState: state)

        XCTAssertFalse(viewItem.switchButtonEnabled)
    }

    func testHintInfo_None() {
        let viewItem = factory.viewItem(forState: state)

        XCTAssertNil(viewItem.hintInfo)
    }

    func testHintInfo_CoinType() {
        state.currencyValue = currencyValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.hintInfo, HintInfo.amount(amountInfo: .currencyValue(currencyValue: currencyValue)))
    }

    func testHintInfo_CurrencyType() {
        state.inputType = .currency
        state.coinValue = coinValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.hintInfo, HintInfo.amount(amountInfo: .coinValue(coinValue: coinValue)))
    }

    func testHintInfo_Error() {
        let amountError: AmountError = .insufficientAmount(amountInfo: .coinValue(coinValue: coinValue))
        state.currencyValue = currencyValue
        state.amountError = amountError

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.hintInfo, HintInfo.error(error: amountError))
    }

    func testAddressInfo() {
        let address = "address"

        state.address = address

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.addressInfo, AddressInfo.address(address: address))
    }

    func testAddressInfo_WithError() {
        let address = "address"
        let addressError: AddressError = .invalidAddress

        state.address = address
        state.addressError = addressError

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.addressInfo, AddressInfo.invalidAddress(address: address, error: addressError))
    }

    func testPrimaryFeeInfo_CoinType() {
        state.inputType = .coin
        state.feeCoinValue = coinValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.primaryFeeInfo, AmountInfo.coinValue(coinValue: coinValue))
    }

    func testPrimaryFeeInfo_CurrencyType() {
        state.inputType = .currency
        state.feeCurrencyValue = currencyValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.primaryFeeInfo, AmountInfo.currencyValue(currencyValue: currencyValue))
    }

    func testSecondaryFeeInfo_CoinType() {
        state.inputType = .coin
        state.feeCurrencyValue = currencyValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.secondaryFeeInfo, AmountInfo.currencyValue(currencyValue: currencyValue))
    }

    func testSecondaryFeeInfo_CurrencyType() {
        state.inputType = .currency
        state.feeCoinValue = coinValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertEqual(viewItem.secondaryFeeInfo, AmountInfo.coinValue(coinValue: coinValue))
    }

    func testSendButtonEnabled_ZeroAmount() {
        state.coinValue = CoinValue(coin: coinValue.coin, value: 0)
        state.address = "address"

        let viewItem = factory.viewItem(forState: state)

        XCTAssertFalse(viewItem.sendButtonEnabled)
    }

    func testSendButtonEnabled_AmountError() {
        state.coinValue = coinValue
        state.address = "address"
        state.amountError = .insufficientAmount(amountInfo: .coinValue(coinValue: coinValue))

        let viewItem = factory.viewItem(forState: state)

        XCTAssertFalse(viewItem.sendButtonEnabled)
    }

    func testSendButtonEnabled_AddressError() {
        state.coinValue = coinValue
        state.address = "address"
        state.addressError = .invalidAddress

        let viewItem = factory.viewItem(forState: state)

        XCTAssertFalse(viewItem.sendButtonEnabled)
    }

    func testSendButtonEnabled_NoAddress() {
        state.coinValue = coinValue

        let viewItem = factory.viewItem(forState: state)

        XCTAssertFalse(viewItem.sendButtonEnabled)
    }

    func testSendButtonEnabled_True() {
        state.coinValue = coinValue
        state.address = "address"

        let viewItem = factory.viewItem(forState: state)

        XCTAssertTrue(viewItem.sendButtonEnabled)
    }

    func testConfirmation_CoinValue() {
        let viewItem = factory.confirmationViewItem(forState: confirmationState)
        XCTAssertEqual(viewItem?.coinValue, coinValue)
    }

    func testConfirmation_CurrencyValue() {
        confirmationState.currencyValue = currencyValue

        let viewItem = factory.confirmationViewItem(forState: confirmationState)

        XCTAssertEqual(viewItem?.currencyValue, currencyValue)
    }

    func testConfirmation_Address() {
        let viewItem = factory.confirmationViewItem(forState: confirmationState)
        XCTAssertEqual(viewItem?.address, address)
    }

    func testConfirmation_FeeInfo_WithoutCurrencyValue() {
        let viewItem = factory.confirmationViewItem(forState: confirmationState)
        XCTAssertEqual(viewItem?.feeInfo, AmountInfo.coinValue(coinValue: feeCoinValue))
    }

    func testConfirmation_FeeInfo_WithCurrencyValue() {
        confirmationState.currencyValue = currencyValue
        confirmationState.feeCurrencyValue = feeCurrencyValue

        let viewItem = factory.confirmationViewItem(forState: confirmationState)

        XCTAssertEqual(viewItem?.feeInfo, AmountInfo.currencyValue(currencyValue: feeCurrencyValue))
    }

    func testConfirmation_TotalInfo_WithoutCurrencyValue() {
        let totalValue = coinValue.value + feeCoinValue.value

        let viewItem = factory.confirmationViewItem(forState: confirmationState)

        XCTAssertEqual(viewItem?.totalInfo, AmountInfo.coinValue(coinValue: CoinValue(coin: coinValue.coin, value: totalValue)))
    }

    func testConfirmation_TotalInfo_WithCurrencyValue() {
        confirmationState.currencyValue = currencyValue
        confirmationState.feeCurrencyValue = feeCurrencyValue

        let totalValue = currencyValue.value + feeCurrencyValue.value

        let viewItem = factory.confirmationViewItem(forState: confirmationState)

        XCTAssertEqual(viewItem?.totalInfo, AmountInfo.currencyValue(currencyValue: CurrencyValue(currency: currencyValue.currency, value: totalValue)))
    }

}
