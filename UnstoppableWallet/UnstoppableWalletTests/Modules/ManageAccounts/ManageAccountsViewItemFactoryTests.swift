//import XCTest
//import Quick
//import Nimble
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class ManageAccountsViewItemFactoryTests: QuickSpec {
//
//    override func spec() {
//        let title = "Mnemonic"
//        let coinCodes = "BTC, ETH"
//
//        let mockType = MockIPredefinedAccountType()
//
//        let factory = ManageAccountsViewItemFactory()
//
//        beforeEach {
//            stub(mockType) { mock in
//                when(mock.title.get).thenReturn(title)
//                when(mock.coinCodes.get).thenReturn(coinCodes)
//                when(mock.defaultAccountType.get).thenReturn(DefaultAccountType.mnemonic(wordsCount: 12))
//            }
//        }
//
//        afterEach {
//            reset(mockType)
//        }
//
//        describe("view item") {
//
//            describe("title and coin codes") {
//                let item = ManageAccountItem(predefinedAccountType: mockType, account: nil)
//
//                it("sets them from predefined account type") {
//                    let viewItem = factory.viewItem(item: item)
//
//                    expect(viewItem.title).to(equal(title))
//                    expect(viewItem.coinCodes).to(equal(coinCodes))
//                }
//            }
//
//            describe("highlighted state") {
//
//                context("when account does not exist") {
//                    let item = ManageAccountItem(predefinedAccountType: mockType, account: nil)
//
//                    it("sets false") {
//                        let viewItem = factory.viewItem(item: item)
//
//                        expect(viewItem.highlighted).to(equal(false))
//                    }
//                }
//
//                context("when account exists") {
//
//                    let item = ManageAccountItem(predefinedAccountType: mockType, account: Account.mock(backedUp: false))
//
//                    it("sets true") {
//                        let viewItem = factory.viewItem(item: item)
//
//                        expect(viewItem.highlighted).to(equal(true))
//                    }
//                }
//            }
//
//            describe("button states") {
//
//                context("when account does not exist") {
//                    let item = ManageAccountItem(predefinedAccountType: mockType, account: nil)
//
//                    it("sets .notLinked") {
//                        let viewItem = factory.viewItem(item: item)
//
//                        expect(viewItem.leftButtonState).to(equal(ManageAccountLeftButtonState.create))
//                        expect(viewItem.rightButtonState).to(equal(ManageAccountRightButtonState.restore))
//                    }
//                }
//
//                context("when account exists") {
//
//                    context("if account is not backed up") {
//                        let item = ManageAccountItem(predefinedAccountType: mockType, account: Account.mock(backedUp: false))
//
//                        it("sets .linked with backedUp to be false") {
//                            let viewItem = factory.viewItem(item: item)
//
//                            expect(viewItem.leftButtonState).to(equal(ManageAccountLeftButtonState.delete))
//                            expect(viewItem.rightButtonState).to(equal(ManageAccountRightButtonState.backup))
//                        }
//                    }
//
//                    context("if account is backed up") {
//                        let item = ManageAccountItem(predefinedAccountType: mockType, account: Account.mock(backedUp: true))
//
//                        it("sets .linked with backedUp to be true") {
//                            let viewItem = factory.viewItem(item: item)
//
//                            expect(viewItem.leftButtonState).to(equal(ManageAccountLeftButtonState.delete))
//                            expect(viewItem.rightButtonState).to(equal(ManageAccountRightButtonState.show))
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//}
