import XCTest
import Quick
import Nimble
import Cuckoo
@testable import Bank_Dev_T

class CreateWalletPresenterTests: QuickSpec {

    override func spec() {
        let mockInteractor = MockICreateWalletInteractor()
        let mockRouter = MockICreateWalletRouter()
        let mockView = MockICreateWalletView()
        let mockState = MockCreateWalletState()

        let presenter = CreateWalletPresenter(interactor: mockInteractor, router: mockRouter, state: mockState)

        beforeEach {
            presenter.view = mockView

            stub(mockView) { mock in
                when(mock.set(createButtonEnabled: any())).thenDoNothing()
            }
            stub(mockState) { mock in
                when(mock.enabledIndexes.set(any())).thenDoNothing()
            }
        }

        afterEach {
            reset(mockRouter)
            reset(mockInteractor)
            reset(mockView)
            reset(mockState)
        }

        describe("ICreateWalletViewDelegate") {

            describe("#viewDidLoad") {

                beforeEach {
                    stub(mockView) { mock in
                        when(mock.set(viewItems: any())).thenDoNothing()
                    }
                    stub(mockState) { mock in
                        when(mock.coins.set(any())).thenDoNothing()
                    }
                }

                describe("view items") {
                    let titleBtc = "Bitcoin"
                    let codeBtc = "BTC"
                    let titleEth = "Ethereum"
                    let codeEth = "ETH"

                    let coinBtc = Coin.mock(title: titleBtc, code: codeBtc)
                    let coinEth = Coin.mock(title: titleEth, code: codeEth)

                    let featuredCoinBtc = FeaturedCoin.mock(coin: coinBtc, enabledByDefault: false)
                    let featuredCoinEth = FeaturedCoin.mock(coin: coinEth, enabledByDefault: true)

                    let viewItemBtc = CreateWalletViewItem(title: titleBtc, code: codeBtc, selected: false)
                    let viewItemEth = CreateWalletViewItem(title: titleEth, code: codeEth, selected: true)

                    beforeEach {
                        stub(mockInteractor) { mock in
                            when(mock.featuredCoins.get).thenReturn([featuredCoinBtc, featuredCoinEth])
                        }

                        presenter.viewDidLoad()
                    }

                    it("sets view items to view") {
                        verify(mockView).set(viewItems: equal(to: [viewItemBtc, viewItemEth]))
                    }
                }

                describe("coins to state") {
                    let coinBtc = Coin.mock()
                    let coinEth = Coin.mock()

                    beforeEach {
                        stub(mockInteractor) { mock in
                            when(mock.featuredCoins.get).thenReturn([FeaturedCoin.mock(coin: coinBtc), FeaturedCoin.mock(coin: coinEth)])
                        }

                        presenter.viewDidLoad()
                    }

                    it("sets featured coins to state") {
                        verify(mockState).coins.set(equal(to: [coinBtc, coinEth]))
                    }
                }

                describe("create button state") {

                    context("when there is at least one enabled featured coin") {
                        let featuredCoins = [
                            FeaturedCoin.mock(enabledByDefault: false),
                            FeaturedCoin.mock(enabledByDefault: true),
                            FeaturedCoin.mock(enabledByDefault: true)
                        ]

                        beforeEach {
                            stub(mockInteractor) { mock in
                                when(mock.featuredCoins.get).thenReturn(featuredCoins)
                            }

                            presenter.viewDidLoad()
                        }

                        it("sets create button enabled true to view") {
                            verify(mockView).set(createButtonEnabled: true)
                        }

                        it("sets correct enabled indexes to state") {
                            verify(mockState).enabledIndexes.set(equal(to: [1, 2]))
                        }
                    }

                    context("when there is no enabled featured coins") {
                        let featuredCoins = [
                            FeaturedCoin.mock(enabledByDefault: false),
                            FeaturedCoin.mock(enabledByDefault: false)
                        ]

                        beforeEach {
                            stub(mockInteractor) { mock in
                                when(mock.featuredCoins.get).thenReturn(featuredCoins)
                            }

                            presenter.viewDidLoad()
                        }

                        it("sets create button enabled false to view") {
                            verify(mockView).set(createButtonEnabled: false)
                        }

                        it("sets empty enabled indexes to state") {
                            verify(mockState).enabledIndexes.set(equal(to: []))
                        }
                    }
                }
            }

            describe("#didToggle") {

                describe("update state") {

                    context("when coin is enabled") {
                        beforeEach {
                            stub(mockState) { mock in
                                when(mock.enabledIndexes.get).thenReturn([0, 2])
                            }

                            presenter.didToggle(index: 1, isOn: true)
                        }

                        it("adds index to enabled indexes") {
                            verify(mockState).enabledIndexes.set(equal(to: [0, 1, 2]))
                        }
                    }

                    context("when coin is disabled") {
                        beforeEach {
                            stub(mockState) { mock in
                                when(mock.enabledIndexes.get).thenReturn([0, 2])
                            }

                            presenter.didToggle(index: 0, isOn: false)
                        }

                        it("adds index to enabled indexes") {
                            verify(mockState).enabledIndexes.set(equal(to: [2]))
                        }
                    }
                }

                describe("update create button state in view") {

                    context("when coin is enabled") {

                        context("when there is no enabled coins") {
                            beforeEach {
                                stub(mockState) { mock in
                                    when(mock.enabledIndexes.get).thenReturn([])
                                }

                                presenter.didToggle(index: 1, isOn: true)
                            }

                            it("sets create button is enabled in view") {
                                verify(mockView).set(createButtonEnabled: true)
                            }
                        }

                        context("when there is at least one enabled coin") {
                            beforeEach {
                                stub(mockState) { mock in
                                    when(mock.enabledIndexes.get).thenReturn([1, 2])
                                }

                                presenter.didToggle(index: 0, isOn: true)
                            }

                            it("does not trigger create button enabled in view") {
                                verify(mockView, never()).set(createButtonEnabled: any())
                            }
                        }

                    }

                    context("when coin is disabled") {

                        context("when last coin is disabled") {
                            beforeEach {
                                stub(mockState) { mock in
                                    when(mock.enabledIndexes.get).thenReturn([1])
                                }

                                presenter.didToggle(index: 1, isOn: false)
                            }

                            it("sets create button is disabled in view") {
                                verify(mockView).set(createButtonEnabled: false)
                            }
                        }

                        context("when non-last coin is disabled") {
                            beforeEach {
                                stub(mockState) { mock in
                                    when(mock.enabledIndexes.get).thenReturn([1, 2])
                                }

                                presenter.didToggle(index: 1, isOn: false)
                            }

                            it("does not trigger create button disabled in view") {
                                verify(mockView, never()).set(createButtonEnabled: any())
                            }
                        }
                    }
                }
            }
        }
    }
}
