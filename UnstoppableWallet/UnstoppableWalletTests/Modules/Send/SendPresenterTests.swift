//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class SendPresenterTests: XCTestCase {
//    private var mockRouter: MockISendRouter!
//    private var mockInteractor: MockISendInteractor!
//    private var mockView: MockISendView!
//    private var mockFactory: MockISendStateViewItemFactory!
//    private var mockUserInput: MockSendUserInput!
//
//    private var feeInfo = FeeInfo()
//    private let decimal: Int = 8
//    private var viewItem = SendStateViewItem(decimal: 8)
//    private var confirmationViewItem: SendConfirmationViewItem!
//
//    private let coin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
//    private let state = SendState(decimal: 8, inputType: .coin)
//
//    private let feeRatePriority: FeeRatePriority = .medium
//
//    private let inputType: SendInputType = .coin
//    private let amount: Decimal = 123.45
//    private let convertedAmount: Decimal = 543.21
//    private let amountInfo: AmountInfo = .coinValue(coinValue: CoinValue(coinCode: "BTC", value: 10.2))
//
//    private let feeRatePercent: Int = 20
//
//    private var presenter: SendPresenter!
//
//    override func setUp() {
//        super.setUp()
//
//        feeInfo.primaryFeeInfo = amountInfo
//        feeInfo.secondaryFeeInfo = amountInfo
//
//        viewItem.amountInfo = amountInfo
//        viewItem.switchButtonEnabled = true
//        viewItem.hintInfo = .error(error: amountInfo)
//        viewItem.addressInfo = .address(address: "address")
//        viewItem.feeInfo = feeInfo
//        viewItem.sendButtonEnabled = false
//
//        confirmationViewItem = SendConfirmationViewItem(
//                coin: coin,
//                primaryAmountInfo: amountInfo,
//                address: "address",
//                feeInfo: amountInfo,
//                totalInfo: amountInfo
//        )
//
//        mockRouter = MockISendRouter()
//        mockInteractor = MockISendInteractor()
//        mockView = MockISendView()
//        mockFactory = MockISendStateViewItemFactory()
//        mockUserInput = MockSendUserInput()
//
//        stub(mockView) { mock in
//            when(mock.set(coin: any())).thenDoNothing()
//            when(mock.set(amountInfo: any())).thenDoNothing()
//            when(mock.set(switchButtonEnabled: any())).thenDoNothing()
//            when(mock.set(hintInfo: any())).thenDoNothing()
//            when(mock.set(addressInfo: any())).thenDoNothing()
//            when(mock.set(feeInfo: any())).thenDoNothing()
//            when(mock.set(sendButtonEnabled: any())).thenDoNothing()
//            when(mock.set(decimal: any())).thenDoNothing()
//            when(mock.showCopied()).thenDoNothing()
//            when(mock.showProgress()).thenDoNothing()
//            when(mock.showConfirmation(viewItem: any())).thenDoNothing()
//            when(mock.dismissWithSuccess()).thenDoNothing()
//        }
//        stub(mockInteractor) { mock in
//            when(mock.coin.get).thenReturn(coin)
//            when(mock.state(forUserInput: sameInstance(as: mockUserInput))).thenReturn(state)
//            when(mock.convertedAmount(forInputType: equal(to: inputType), amount: equal(to: amount))).thenReturn(convertedAmount)
//            when(mock.copy(address: any())).thenDoNothing()
//            when(mock.send(userInput: any())).thenDoNothing()
//            when(mock.set(inputType: any())).thenDoNothing()
//            when(mock.retrieveRate()).thenDoNothing()
//            when(mock.totalBalanceMinusFee(forInputType: any(), address: any(), feeRatePriority: any())).thenReturn(0)
//            when(mock.defaultInputType.get).thenReturn(SendInputType.coin)
//        }
//        stub(mockFactory) { mock in
//            when(mock.viewItem(forState: equal(to: state), forceRoundDown: any())).thenReturn(viewItem)
//            when(mock.confirmationViewItem(forState: equal(to: state), coin: equal(to: coin))).thenReturn(confirmationViewItem)
//        }
//        stub(mockUserInput) { mock in
//            when(mock.inputType.get).thenReturn(inputType)
//            when(mock.amount.get).thenReturn(amount)
//            when(mock.inputType.set(any())).thenDoNothing()
//            when(mock.feeRatePriority.get).thenReturn(feeRatePriority)
//            when(mock.feeRatePriority.set(any())).thenDoNothing()
//            when(mock.amount.set(any())).thenDoNothing()
//            when(mock.address.set(any())).thenDoNothing()
//        }
//
//        presenter = SendPresenter(interactor: mockInteractor, router: mockRouter, factory: mockFactory, userInput: mockUserInput)
//        presenter.view = mockView
//    }
//
//    override func tearDown() {
//        mockRouter = nil
//        mockInteractor = nil
//        mockView = nil
//        mockFactory = nil
//        mockUserInput = nil
//
//        confirmationViewItem = nil
//
//        presenter = nil
//
//        super.tearDown()
//    }
//
//    func testOnViewDidLoad() {
//        let defaultInputType = SendInputType.currency
//
//        stub(mockInteractor) { mock in
//            when(mock.defaultInputType.get).thenReturn(defaultInputType)
//        }
//
//        presenter.onViewDidLoad()
//
//        verify(mockUserInput).inputType.set(equal(to: defaultInputType))
//
//        verify(mockView).set(decimal: equal(to: decimal))
//        verify(mockView).set(coin: equal(to: coin))
//        verify(mockView).set(amountInfo: equal(to: viewItem.amountInfo))
//        verify(mockView).set(switchButtonEnabled: viewItem.switchButtonEnabled)
//        verify(mockView).set(hintInfo: equal(to: viewItem.hintInfo))
//        verify(mockView).set(addressInfo: equal(to: viewItem.addressInfo))
//        verify(mockView).set(feeInfo: equal(to: feeInfo))
//        verify(mockView).set(sendButtonEnabled: viewItem.sendButtonEnabled)
//
//        verify(mockInteractor).retrieveRate()
//    }
//
//    func testOnSwitchClicked_UpdateView() {
//        presenter.onSwitchClicked()
//
//        verify(mockView).set(decimal: equal(to: decimal))
//        verify(mockView).set(amountInfo: equal(to: viewItem.amountInfo))
//        verify(mockView).set(hintInfo: equal(to: viewItem.hintInfo))
//        verify(mockView).set(feeInfo: equal(to: feeInfo))
//    }
//
//    func testOnSwitchClicked_FromCoinToCurrency() {
//        presenter.onSwitchClicked()
//
//        verify(mockUserInput).inputType.set(equal(to: SendInputType.currency))
//        verify(mockUserInput).amount.set(equal(to: convertedAmount))
//        verify(mockInteractor).set(inputType: equal(to: SendInputType.currency))
//    }
//
//    func testOnSwitchClicked_FromCurrencyToCoin() {
//        let inputType: SendInputType = .currency
//        stub(mockInteractor) { mock in
//            when(mock.convertedAmount(forInputType: equal(to: inputType), amount: equal(to: amount))).thenReturn(convertedAmount)
//        }
//        stub(mockUserInput) { mock in
//            when(mock.inputType.get).thenReturn(inputType)
//        }
//
//        presenter.onSwitchClicked()
//
//        verify(mockUserInput).inputType.set(equal(to: SendInputType.coin))
//        verify(mockUserInput).amount.set(equal(to: convertedAmount))
//        verify(mockInteractor).set(inputType: equal(to: SendInputType.coin))
//    }
//
//    func testOnSwitchClicked_NoConvertedAmount() {
//        stub(mockInteractor) { mock in
//            when(mock.convertedAmount(forInputType: equal(to: inputType), amount: equal(to: amount))).thenReturn(nil)
//        }
//
//        presenter.onSwitchClicked()
//
//        verify(mockUserInput, never()).inputType.set(any())
//        verify(mockUserInput, never()).amount.set(any())
//        verifyNoMoreInteractions(mockView)
//    }
//
//    func testOnAmountChanged() {
//        let newAmount: Decimal = 987.65
//
//        presenter.onAmountChanged(amount: newAmount)
//
//        verify(mockUserInput).amount.set(equal(to: newAmount))
//
//        verify(mockView).set(hintInfo: equal(to: viewItem.hintInfo))
//        verify(mockView).set(feeInfo: equal(to: feeInfo))
//        verify(mockView).set(sendButtonEnabled: viewItem.sendButtonEnabled)
//    }
//
//    func testOnPasteClicked_HasAddress() {
//        let address = "address"
//
//        stub(mockInteractor) { mock in
//            when(mock.valueFromPasteboard.get).thenReturn(address)
//            when(mock.parse(paymentAddress: equal(to: address))).thenReturn(PaymentRequestAddress(address: address))
//        }
//
//        presenter.onPasteAddressClicked()
//
//        verify(mockUserInput).address.set(equal(to: address))
//
//        verify(mockView).set(addressInfo: equal(to: viewItem.addressInfo))
//        verify(mockView).set(feeInfo: equal(to: feeInfo))
//        verify(mockView).set(sendButtonEnabled: viewItem.sendButtonEnabled)
//    }
//
//    func testOnPasteClicked_NoAddress() {
//        stub(mockInteractor) { mock in
//            when(mock.valueFromPasteboard.get).thenReturn(nil)
//        }
//
//        presenter.onPasteAddressClicked()
//
//        verifyNoMoreInteractions(mockUserInput)
//        verifyNoMoreInteractions(mockView)
//    }
//
//    func testOnScanAddress() {
//        let address = "address"
//
//        stub(mockInteractor) { mock in
//            when(mock.parse(paymentAddress: equal(to: address))).thenReturn(PaymentRequestAddress(address: address))
//        }
//
//        presenter.onScan(address: address)
//
//        verify(mockUserInput).address.set(equal(to: address))
//
//        verify(mockView).set(addressInfo: equal(to: viewItem.addressInfo))
//        verify(mockView).set(feeInfo: equal(to: feeInfo))
//        verify(mockView).set(sendButtonEnabled: viewItem.sendButtonEnabled)
//    }
//
//    func testOnDeleteClicked() {
//        presenter.onAddressDeleteClicked()
//
//        verify(mockUserInput).address.set(equal(to: nil))
//
//        verify(mockView).set(addressInfo: equal(to: viewItem.addressInfo))
//        verify(mockView).set(feeInfo: equal(to: feeInfo))
//        verify(mockView).set(sendButtonEnabled: viewItem.sendButtonEnabled)
//    }
//
//    func testOnSendClicked() {
//        presenter.onSendClicked()
//
//        verify(mockView).showConfirmation(viewItem: equal(to: confirmationViewItem))
//    }
//
//    func testOnSendClicked_NoViewItem() {
//        stub(mockFactory) { mock in
//            when(mock.confirmationViewItem(forState: equal(to: state), coin: equal(to: coin))).thenReturn(nil)
//        }
//
//        presenter.onSendClicked()
//
//        verify(mockView, never()).showConfirmation(viewItem: any())
//    }
//
//    func testOnConfirmClicked() {
//        presenter.onConfirmClicked()
//
//        verify(mockInteractor).send(userInput: equal(to: mockUserInput))
//        verify(mockView).showProgress()
//    }
//
//    func testOnCopyAddress() {
//        let address = "some_test_address"
//
//        stub(mockUserInput) { mock in
//            when(mock.address.get).thenReturn(address)
//        }
//
//        presenter.onCopyAddress()
//
//        verify(mockInteractor).copy(address: equal(to: address))
//        verify(mockView).showCopied()
//    }
//
//    func testOnMaxClicked() {
//        let maxBalance: Decimal = 15
//        let address = "some_test_address"
//
//        stub(mockUserInput) { mock in
//            when(mock.address.get).thenReturn(address)
//        }
//        stub(mockInteractor) { mock in
//            when(mock.totalBalanceMinusFee(forInputType: equal(to: inputType), address: equal(to: address), feeRatePriority: equal(to: feeRatePriority))).thenReturn(maxBalance)
//        }
//
//        presenter.onMaxClicked()
//
//        verify(mockFactory).viewItem(forState: equal(to: state), forceRoundDown: true)
//        verify(mockInteractor).totalBalanceMinusFee(forInputType: equal(to: inputType), address: equal(to: address), feeRatePriority: equal(to: feeRatePriority))
//        verify(mockView).set(amountInfo: equal(to: amountInfo))
//    }
//
//    func testPasteAmount() {
//        let stringAmount = "1.234"
//        let expectedAmount = Decimal(string: stringAmount)!
//        let expectedAmountInfo = AmountInfo.coinValue(coinValue: CoinValue(coinCode: coin.code, value: expectedAmount))
//        viewItem.amountInfo = expectedAmountInfo
//
//        stub(mockInteractor) { mock in
//            when(mock.valueFromPasteboard.get).thenReturn(stringAmount)
//        }
//        stub(mockFactory) { mock in
//            when(mock.viewItem(forState: equal(to: state), forceRoundDown: false)).thenReturn(viewItem)
//        }
//
//        presenter.onPasteAmountClicked()
//
//        verify(mockUserInput).amount.set(equal(to: expectedAmount))
//        verify(mockView).set(amountInfo: equal(to: expectedAmountInfo))
//    }
//
//    func testFeePriorityChange() {
//        presenter.onFeePriorityChange(value: 2)
//
//        verify(mockUserInput).feeRatePriority.set(equal(to: FeeRatePriority.medium))
//
//        verify(mockView).set(hintInfo: equal(to: viewItem.hintInfo))
//        verify(mockView).set(feeInfo: equal(to: feeInfo))
//        verify(mockView).set(sendButtonEnabled: viewItem.sendButtonEnabled)
//    }
//
//    func testFeePriorityChange_fallback() {
//        presenter.onFeePriorityChange(value: 16)
//
//        verify(mockUserInput).feeRatePriority.set(equal(to: FeeRatePriority.medium))
//    }
//
//    func testIsFeeAdjustable() {
//        XCTAssertEqual(true, presenter.isFeeAdjustable)
//    }
//
//    func testOnBecomeActive() {
//        presenter.onBecomeActive()
//
//        verify(mockInteractor).retrieveRate()
//    }
//
//    func testDidUpdateRate() {
//        state.inputType = .currency
//
//        presenter.didRetrieve(rate: Rate(coinCode: coin.code, currencyCode: "$", value: 1, date: Date(), isLatest: true))
//
//        verify(mockFactory).viewItem(forState: sameInstance(as: state), forceRoundDown: equal(to: false))
//
//        verify(mockView).set(feeInfo: equal(to: feeInfo))
//        verify(mockView).set(hintInfo: equal(to: viewItem.hintInfo))
//        verify(mockView).set(switchButtonEnabled: viewItem.switchButtonEnabled)
//        verify(mockView).set(amountInfo: equal(to: viewItem.amountInfo))
//        verify(mockView).set(decimal: equal(to: decimal))
//    }
//
//}
