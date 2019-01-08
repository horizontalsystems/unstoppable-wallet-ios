import XCTest
import Cuckoo
@testable import Bank_Dev_T

class SendInteractorTests: XCTestCase {
    enum StubError: Error { case some }

    private var mockDelegate: MockISendInteractorDelegate!
    private var mockCurrencyManager: MockICurrencyManager!
    private var mockRateManager: MockIRateManager!
    private var mockPasteboardManager: MockIPasteboardManager!
    private var mockRate: MockRate!

    private let coin = "BTC"
    private let rateValue = 6543.21
    private let baseCurrency = Currency(code: "USD", symbol: "$")
    private let balance = 123.45

    private var mockAdapter: MockIAdapter!
    private var wallet: Wallet!
    private var input = SendUserInput()

    private var interactor: SendInteractor!

    override func setUp() {
        super.setUp()

        mockAdapter = MockIAdapter()
        wallet = Wallet(title: "some", coinCode: coin, adapter: mockAdapter)

        mockDelegate = MockISendInteractorDelegate()
        mockCurrencyManager = MockICurrencyManager()
        mockRateManager = MockIRateManager()
        mockPasteboardManager = MockIPasteboardManager()
        mockRate = MockRate()

        stub(mockCurrencyManager) { mock in
            when(mock.baseCurrency.get).thenReturn(baseCurrency)
        }
        stub(mockRateManager) { mock in
            when(mock.rate(forCoin: coin, currencyCode: baseCurrency.code)).thenReturn(mockRate)
        }
        stub(mockRate) { mock in
            when(mock.value.get).thenReturn(rateValue)
            when(mock.expired.get).thenReturn(false)
        }
        stub(mockAdapter) { mock in
            when(mock.balance.get).thenReturn(balance)
            when(mock.validate(address: any())).thenDoNothing()
            when(mock.fee(for: any(), address: any(), senderPay: any())).thenReturn(0)
        }
        stub(mockPasteboardManager) { mock in
            when(mock.set(value: any())).thenDoNothing()
        }

        initInteractor()
    }

    override func tearDown() {
        mockDelegate = nil
        mockCurrencyManager = nil
        mockRateManager = nil
        mockPasteboardManager = nil
        mockRate = nil

        mockAdapter = nil
        wallet = nil

        interactor = nil

        super.tearDown()
    }

    private func initInteractor() {
        interactor = SendInteractor(currencyManager: mockCurrencyManager, rateManager: mockRateManager, pasteboardManager: mockPasteboardManager, wallet: wallet)
        interactor.delegate = mockDelegate
    }

    func testAddressFromPasteboard() {
        let address = "address"

        stub(mockPasteboardManager) { mock in
            when(mock.value.get).thenReturn(address)
        }

        XCTAssertEqual(interactor.addressFromPasteboard, address)
    }

    func testConvertedAmount_FromCoinToCurrency() {
        let amount = 123.45
        let expectedAmount = amount * rateValue

        XCTAssertEqual(interactor.convertedAmount(forInputType: .coin, amount: amount), expectedAmount)
    }

    func testConvertedAmount_FromCurrencyToCoin() {
        let amount = 123.45
        let expectedAmount = amount / rateValue

        XCTAssertEqual(interactor.convertedAmount(forInputType: .currency, amount: amount), expectedAmount)
    }

    func testConvertedAmount_NoRate() {
        stub(mockRateManager) { mock in
            when(mock.rate(forCoin: coin, currencyCode: baseCurrency.code)).thenReturn(nil)
        }

        initInteractor()

        XCTAssertEqual(interactor.convertedAmount(forInputType: .coin, amount: 123.45), nil)
    }

    func testState_InputType_Coin() {
        input.inputType = .coin

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.inputType, SendInputType.coin)
    }

    func testState_InputType_Currency() {
        input.inputType = .currency

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.inputType, SendInputType.currency)
    }

    func testState_CoinValue_CoinType() {
        let amount = 123.45

        input.inputType = .coin
        input.amount = amount

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.coinValue, CoinValue(coinCode: coin, value: amount))
    }

    func testState_CoinValue_CurrencyType() {
        let amount = 123.45

        input.inputType = .currency
        input.amount = amount

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.coinValue, CoinValue(coinCode: coin, value: amount / rateValue))
    }

    func testState_CoinValue_CurrencyType_NoRate() {
        stub(mockRateManager) { mock in
            when(mock.rate(forCoin: coin, currencyCode: baseCurrency.code)).thenReturn(nil)
        }

        initInteractor()

        input.inputType = .currency

        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.coinValue)
    }

    func testState_CoinValue_CurrencyType_ExpiredRate() {
        stub(mockRate) { mock in
            when(mock.expired.get).thenReturn(true)
        }

        initInteractor()

        input.inputType = .currency

        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.coinValue)
    }

    func testState_CurrencyValue_CoinType() {
        let amount = 123.45

        input.inputType = .coin
        input.amount = amount

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.currencyValue, CurrencyValue(currency: baseCurrency, value: amount * rateValue))
    }

    func testState_CurrencyValue_CurrencyType() {
        let amount = 123.45

        input.inputType = .currency
        input.amount = amount

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.currencyValue, CurrencyValue(currency: baseCurrency, value: amount))
    }

    func testState_CurrencyValue_CoinType_NoRate() {
        stub(mockRateManager) { mock in
            when(mock.rate(forCoin: coin, currencyCode: baseCurrency.code)).thenReturn(nil)
        }

        initInteractor()

        input.inputType = .coin

        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.currencyValue)
    }

    func testState_AmountError_CoinType_EnoughBalance() {
        input.inputType = .coin
        input.amount = balance - 1

        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.amountError)
    }

    func testState_AmountError_CoinType_InsufficientBalance() {
        let address = "address"
        input.inputType = .coin
        input.amount = balance + 1
        input.address = address

        let fee: Double = 0.00000123
        let expectedAvailableBalance: Double = 123.45 - fee

        stub(mockAdapter) { mock in
            when(mock.fee(for: equal(to: input.amount), address: equal(to: address), senderPay: true)).thenThrow(FeeError.insufficientAmount(fee: fee))
        }

        let state = interactor.state(forUserInput: input)

        let expectedAmountError = AmountError.insufficientAmount(
                amountInfo: .coinValue(coinValue: CoinValue(coinCode: coin, value: expectedAvailableBalance))
        )
        XCTAssertEqual(state.amountError, expectedAmountError)
    }

    func testState_AmountError_CurrencyType_EnoughBalance() {
        let currencyBalance = balance * rateValue
        input.inputType = .currency
        input.amount = currencyBalance - 1

        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.amountError)
    }

    func testState_AmountError_CurrencyType_InsufficientBalance() {
        let currencyBalance = balance * rateValue
        let address = "address"
        input.inputType = .currency
        input.amount = currencyBalance + 1
        input.address = address

        let fee: Double = 0.00000123

        stub(mockAdapter) { mock in
            when(mock.fee(for: any(), address: any(), senderPay: any())).thenThrow(FeeError.insufficientAmount(fee: fee))//any, because 123.45 * 6543.21 / 6543.21 = 123.4501528301858
        }

        let state = interactor.state(forUserInput: input)

        let expectedCurrencyAvailableBalance: Double = (123.45 - fee) * rateValue
        let expectedAmountError = AmountError.insufficientAmount(
                amountInfo: .currencyValue(currencyValue: CurrencyValue(currency: baseCurrency, value: expectedCurrencyAvailableBalance))
        )
        XCTAssertEqual(state.amountError, expectedAmountError)
    }

    func testState_Address() {
        let address = "address"
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.address, address)
    }

    func testState_AddressError_Valid() {
        let state = interactor.state(forUserInput: input)

        XCTAssertNil(state.addressError)
    }

    func testState_AddressError_Invalid() {
        let address = "address"
        input.address = address

        stub(mockAdapter) { mock in
            when(mock.validate(address: equal(to: address))).thenThrow(StubError.some)
        }

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.addressError, AddressError.invalidAddress)
    }

    func testState_FeeCoinValue_CoinType() {
        let fee = 0.123
        let amount = 123.45
        let address = "address"

        stub(mockAdapter) { mock in
            when(mock.fee(for: amount, address: equal(to: address), senderPay: true)).thenReturn(fee)
        }

        input.inputType = .coin
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCoinValue, CoinValue(coinCode: coin, value: fee))
    }

    func testState_FeeCoinValue_CurrencyType() {
        let fee = 0.123
        let amount = 123.45
        let address = "address"
        let coinAmount = amount / rateValue

        stub(mockAdapter) { mock in
            when(mock.fee(for: coinAmount, address: equal(to: address), senderPay: true)).thenReturn(fee)
        }

        input.inputType = .currency
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCoinValue, CoinValue(coinCode: coin, value: fee))
    }

    func testState_FeeCurrencyValue_CoinType() {
        let fee = 0.123
        let amount = 123.45
        let address = "address"

        stub(mockAdapter) { mock in
            when(mock.fee(for: amount, address: equal(to: address), senderPay: true)).thenReturn(fee)
        }

        input.inputType = .coin
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCurrencyValue, CurrencyValue(currency: baseCurrency, value: fee * rateValue))
    }

    func testState_FeeCurrencyValue_CoinType_InsufficientBalance() {
        let fee = 0.123
        let amount = 123.45
        let address = "address"

        stub(mockAdapter) { mock in
            when(mock.fee(for: equal(to: amount), address: equal(to: address), senderPay: true)).thenThrow(FeeError.insufficientAmount(fee: fee))
        }

        input.inputType = .coin
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCurrencyValue, CurrencyValue(currency: baseCurrency, value: fee * rateValue))
    }

    func testState_FeeCurrencyValue_CurrencyType() {
        let fee = 0.123
        let amount = 123.45
        let address = "address"
        let coinAmount = amount / rateValue

        stub(mockAdapter) { mock in
            when(mock.fee(for: coinAmount, address: equal(to: address), senderPay: true)).thenReturn(fee)
        }

        input.inputType = .currency
        input.amount = amount
        input.address = address

        let state = interactor.state(forUserInput: input)

        XCTAssertEqual(state.feeCurrencyValue, CurrencyValue(currency: baseCurrency, value: fee * rateValue))
    }

    func testCopyAddress() {
        let address = "some_address"

        interactor.copy(address: address)

        verify(mockPasteboardManager).set(value: equal(to: address))
    }

}
