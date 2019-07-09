import XCTest
import Quick
import Nimble
import Cuckoo
@testable import Bank_Dev_T

class ManageAccountsViewItemFactoryTests: QuickSpec {

    override func spec() {
        let title = "Mnemonic"
        let coinCodes = "BTC, ETH"

        let mockType = MockIPredefinedAccountType()

        let factory = ManageAccountsViewItemFactory()

        beforeEach {
            stub(mockType) { mock in
                when(mock.title.get).thenReturn(title)
                when(mock.coinCodes.get).thenReturn(coinCodes)
            }
        }

        afterEach {
            reset(mockType)
        }

        describe("view item") {
            let item = ManageAccountItem(predefinedAccountType: mockType, account: nil)

            it("sets title and coin codes") {
                let viewItem = factory.viewItem(item: item)

                expect(viewItem.title).to(equal(title))
                expect(viewItem.coinCodes).to(equal(coinCodes))
            }
        }
    }

}
