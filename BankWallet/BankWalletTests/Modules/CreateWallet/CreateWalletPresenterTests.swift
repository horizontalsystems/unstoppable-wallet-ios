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

                    let viewItemBtc = CreateWalletViewItem(title: titleBtc, code: codeBtc)
                    let viewItemEth = CreateWalletViewItem(title: titleEth, code: codeEth)

                    beforeEach {
                        stub(mockInteractor) { mock in
                            when(mock.featuredCoins.get).thenReturn([coinBtc, coinEth])
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
                            when(mock.featuredCoins.get).thenReturn([coinBtc, coinEth])
                        }

                        presenter.viewDidLoad()
                    }

                    it("sets featured coins to state") {
                        verify(mockState).coins.set(equal(to: [coinBtc, coinEth]))
                    }
                }
            }

            describe("#didTap") {
                let selectedCoin = Coin.mock()

                beforeEach {
                    stub(mockState) { mock in
                        when(mock.coins.get).thenReturn([Coin.mock(), selectedCoin])
                    }
                    stub(mockInteractor) { mock in
                        when(mock.createWallet(coin: any())).thenDoNothing()
                    }
                    stub(mockRouter) { mock in
                        when(mock.showMain()).thenDoNothing()
                    }

                    presenter.didTap(index: 1)
                }

                it("creates wallet with selected coin") {
                    verify(mockInteractor).createWallet(coin: equal(to: selectedCoin))
                }

                it("shows Main module") {
                    verify(mockRouter).showMain()
                }
            }
        }
    }
}
