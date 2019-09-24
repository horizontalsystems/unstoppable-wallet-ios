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
        let mockFactory = MockCreateWalletViewItemFactory()

        let presenter = CreateWalletPresenter(interactor: mockInteractor, router: mockRouter, state: mockState, viewItemFactory: mockFactory)

        beforeEach {
            presenter.view = mockView

            stub(mockView) { mock in
                when(mock.set(viewItems: any())).thenDoNothing()
            }
            stub(mockState) { mock in
                when(mock.selectedIndex.set(any())).thenDoNothing()
            }
        }

        afterEach {
            reset(mockRouter)
            reset(mockInteractor)
            reset(mockView)
            reset(mockState)
            reset(mockFactory)
        }

        describe("ICreateWalletViewDelegate") {

            describe("#viewDidLoad") {
                let initialSelectedIndex: Int = 0
                let featuredCoins = [Coin.mock(), Coin.mock()]

                beforeEach {
                    stub(mockState) { mock in
                        when(mock.coins.set(any())).thenDoNothing()
                    }
                    stub(mockFactory) { mock in
                        when(mock.viewItems(coins: any(), selectedIndex: any())).thenReturn([])
                    }
                }

                describe("view items") {
                    let viewItems = [CreateWalletViewItem.mock(), CreateWalletViewItem.mock()]

                    beforeEach {
                        stub(mockInteractor) { mock in
                            when(mock.featuredCoins.get).thenReturn(featuredCoins)
                        }
                        stub(mockFactory) { mock in
                            when(mock.viewItems(coins: equal(to: featuredCoins), selectedIndex: initialSelectedIndex)).thenReturn(viewItems)
                        }

                        presenter.viewDidLoad()
                    }

                    it("sets view items to view") {
                        verify(mockView).set(viewItems: equal(to: viewItems))
                    }
                }

                describe("set data to state") {

                    beforeEach {
                        stub(mockInteractor) { mock in
                            when(mock.featuredCoins.get).thenReturn(featuredCoins)
                        }

                        presenter.viewDidLoad()
                    }

                    it("sets featured coins to state") {
                        verify(mockState).coins.set(equal(to: featuredCoins))
                    }

                    it("sets initial selected index to state") {
                        verify(mockState).selectedIndex.set(equal(to: initialSelectedIndex))
                    }
                }
            }

            describe("#didTap") {
                let index: Int = 1
                let coins = [Coin.mock(), Coin.mock()]
                let viewItems = [CreateWalletViewItem.mock(), CreateWalletViewItem.mock()]

                beforeEach {
                    stub(mockState) { mock in
                        when(mock.coins.get).thenReturn(coins)
                    }
                    stub(mockFactory) { mock in
                        when(mock.viewItems(coins: equal(to: coins), selectedIndex: index)).thenReturn(viewItems)
                    }

                    presenter.didTap(index: index)
                }

                it("sets new view items to view") {
                    verify(mockView).set(viewItems: equal(to: viewItems))
                }

                it("sets new selected index to state") {
                    verify(mockState).selectedIndex.set(equal(to: index))
                }
            }

            describe("#didTapCreateButton") {
                let selectedIndex = 1
                let coinAtSelectedIndex = Coin.mock()

                beforeEach {
                    stub(mockState) { mock in
                        when(mock.selectedIndex.get).thenReturn(selectedIndex)
                        when(mock.coins.get).thenReturn([Coin.mock(), coinAtSelectedIndex])
                    }
                }

                context("when wallet is created without errors") {
                    beforeEach {
                        stub(mockInteractor) { mock in
                            when(mock.createWallet(coin: any())).thenDoNothing()
                        }
                        stub(mockRouter) { mock in
                            when(mock.showMain()).thenDoNothing()
                        }

                        presenter.didTapCreateButton()
                    }

                    it("creates wallet with selected coin") {
                        verify(mockInteractor).createWallet(coin: equal(to: coinAtSelectedIndex))
                    }

                    it("shows Main module") {
                        verify(mockRouter).showMain()
                    }
                }

                context("when wallet is not created and error is thrown") {
                    let error = TestError()

                    beforeEach {
                        stub(mockInteractor) { mock in
                            when(mock.createWallet(coin: any())).thenThrow(error)
                        }
                        stub(mockView) { mock in
                            when(mock.show(error: any())).thenDoNothing()
                        }

                        presenter.didTapCreateButton()
                    }

                    it("shows error in view") {
//                        verify(mockView).show(error: equal(to: error, type: TestError.self))
                    }

                    it("does not show Main module") {
                        verify(mockRouter, never()).showMain()
                    }
                }
            }
        }
    }
}
