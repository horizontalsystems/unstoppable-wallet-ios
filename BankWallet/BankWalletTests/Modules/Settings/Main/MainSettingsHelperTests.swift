import XCTest
import Quick
import Nimble
import Cuckoo
@testable import Bank_Dev_T

class MainSettingsHelperTests: QuickSpec {

    override func spec() {
        let helper = MainSettingsHelper()

        describe("is backed up") {
            context("when backed up count is 0") {
                it("returns true") {
                    expect(helper.isBackedUp(nonBackedUpCount: 0)).to(beTrue())
                }
            }

            context("when backed up count more than 0") {
                it("returns false") {
                    expect(helper.isBackedUp(nonBackedUpCount: 1)).to(beFalse())
                }
            }
        }

        describe("display name for base currency") {
            let code = "KGZ"
            let currency = Currency.mock(code: code)

            it("returns currency code") {
                expect(helper.displayName(baseCurrency: currency)).to(equal(code))
            }
        }
    }

}
