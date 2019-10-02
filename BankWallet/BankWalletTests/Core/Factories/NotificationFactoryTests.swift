import XCTest
import Quick
import Nimble
import Cuckoo
@testable import Bank_Dev_T

class NotificationFactoryTests: QuickSpec {

    override func spec() {
        let mockHelper = MockIEmojiHelper()

        let factory = NotificationFactory(emojiHelper: mockHelper)

        let mockBodyString = "body"
        let mockTitleString = "title"
        let mockMultiString = "multi"
        beforeEach {
            stub(mockHelper) { mock in
                when(mock.body(forState: any())).thenReturn(mockBodyString)
                when(mock.title(forState: any())).thenReturn(mockTitleString)
                when(mock.multiAlerts.get).thenReturn(mockMultiString)
            }
        }

        afterEach {
            reset(mockHelper)
        }

        let firstCoin = Coin.mock(title: "First", code: "FRST")
        let secondCoin = Coin.mock(title: "Second", code: "SCND")
        let thirdCoin = Coin.mock(title: "Third", code: "THRD")

        describe("#notifications") {
            describe("make notification for 1 alert") {
                it("makes notification for up") {
                    let states: [Int] = [2, 3, 5]
                    for state in states {
                        let priceAlertItem = PriceAlertItem(coin: firstCoin, signedState: state)
                        let notifications = factory.notifications(forAlerts: [priceAlertItem])

                        verify(mockHelper).title(forState: equal(to: state))
                        verify(mockHelper).body(forState: equal(to: state))
                        verifyNoMoreInteractions(mockHelper)

                        expect(notifications.count).to(equal(1))
                        expect(notifications[0].title).to(equal("\(firstCoin.title) \(mockTitleString)"))
                        expect(notifications[0].body).to(equal("price_notification.up".localized.capitalized + " \(state)% \(mockBodyString)"))
                    }
                }
                it("makes notification for down") {
                    let states: [Int] = [-2, -3, -5]
                    for state in states {
                        let priceAlertItem = PriceAlertItem(coin: firstCoin, signedState: state)
                        let notifications = factory.notifications(forAlerts: [priceAlertItem])

                        verify(mockHelper).title(forState: equal(to: state))
                        verify(mockHelper).body(forState: equal(to: state))
                        verifyNoMoreInteractions(mockHelper)

                        expect(notifications.count).to(equal(1))
                        expect(notifications[0].title).to(equal("\(firstCoin.title) \(mockTitleString)"))
                        expect(notifications[0].body).to(equal("price_notification.down".localized.capitalized + " \(-state)% \(mockBodyString)"))
                    }
                }
            }
            describe("make notification for 2 alerts") {
                it("makes 2 notifications") {
                    let state = 2
                    let firstPriceAlert = PriceAlertItem(coin: firstCoin, signedState: state)
                    let secondPriceAlert = PriceAlertItem(coin: secondCoin, signedState: state)
                    let notifications = factory.notifications(forAlerts: [firstPriceAlert, secondPriceAlert])

                    verify(mockHelper, times(2)).title(forState: equal(to: state))
                    verify(mockHelper, times(2)).body(forState: equal(to: state))
                    verifyNoMoreInteractions(mockHelper)

                    expect(notifications.count).to(equal(2))
                }
            }
            describe("make notification for 3 alerts") {
                it("makes multi notification") {
                    let firstState = 2
                    let secondState = -5
                    let thirdState = 3
                    let fourthState = -2
                    let alerts = [PriceAlertItem(coin: secondCoin, signedState: secondState),
                                  PriceAlertItem(coin: firstCoin, signedState: firstState),
                                  PriceAlertItem(coin: thirdCoin, signedState: fourthState),
                                  PriceAlertItem(coin: thirdCoin, signedState: thirdState)
                    ]
                    let notifications = factory.notifications(forAlerts: alerts)

                    verify(mockHelper).multiAlerts.get()
                    verifyNoMoreInteractions(mockHelper)

                    expect(notifications.count).to(equal(1))
                    expect(notifications[0].title).to(equal("price_notification.multi_title".localized + " \(mockMultiString)"))

                    var body = "\(thirdCoin.code) " + "price_notification.up".localized + " \(thirdState)%, "
                    body += "\(firstCoin.code) " + "price_notification.up".localized + " \(firstState)%, "
                    body += "\(thirdCoin.code) " + "price_notification.down".localized + " \(-fourthState)%, "
                    body += "\(secondCoin.code) " + "price_notification.down".localized + " \(-secondState)%"
                    expect(notifications[0].body).to(equal(body))
                }
            }
        }
    }

}
