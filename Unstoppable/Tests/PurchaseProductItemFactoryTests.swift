import Foundation
import Testing
@testable import WalletCore

struct PurchaseProductItemFactoryTests {
    private static let annualPrice = Decimal(19999) / 100
    private static let monthlyPrice = Decimal(2499) / 100

    private let factory = PurchaseProductItemFactory()

    private func product(
        type: PurchaseManager.PurchaseType = .subscription,
        period: PurchaseManager.SubscriptionPeriod?,
        price: Decimal,
        currency: String = "USD"
    ) -> PurchaseManager.ProductData {
        let style = Decimal.FormatStyle.Currency(code: currency)

        return PurchaseManager.ProductData(
            id: period?.productName ?? "lifetime",
            type: type,
            period: period,
            price: price,
            priceFormatted: price.formatted(style),
            priceFormatStyle: style,
            introductoryOffer: nil
        )
    }

    @Test func annualProductShowsDiscountAndCurrencyFormattedMonthlyPrice() throws {
        let item = try #require(factory.item(product: product(period: .annually, price: Self.annualPrice), offerWasUsed: false, monthlyPrice: Self.monthlyPrice))

        let badge = try #require(item.discountBadge)
        #expect(badge.hasSuffix("33%"))

        let monthly = (Self.annualPrice / 12).formatted(.currency(code: "USD"))
        let description = try #require(item.priceDescription).description
        #expect(description.contains(monthly))
        #expect(item.priceDescripionAccented)
    }

    @Test(arguments: [nil, Decimal(0)])
    func annualProductWithoutMonthlyPriceHasNoDiscount(monthlyPrice: Decimal?) throws {
        let item = try #require(factory.item(product: product(period: .annually, price: Self.annualPrice), offerWasUsed: false, monthlyPrice: monthlyPrice))

        #expect(item.discountBadge == nil)
        #expect(item.priceDescription == nil)
        #expect(!item.priceDescripionAccented)
    }

    @Test func monthlyProductHasNoDiscountOrDescription() throws {
        let item = try #require(factory.item(product: product(period: .monthly, price: Self.monthlyPrice), offerWasUsed: false, monthlyPrice: Self.monthlyPrice))

        #expect(item.discountBadge == nil)
        #expect(item.priceDescription == nil)
    }

    @Test func lifetimeProductShowsPriceAndSuffixAsOneString() throws {
        let lifetime = product(type: .lifetime, period: nil, price: Decimal(49999) / 100)
        let item = try #require(factory.item(product: lifetime, offerWasUsed: false, monthlyPrice: Self.monthlyPrice))

        #expect(item.discountBadge == nil)
        #expect(item.price.description.contains(lifetime.priceFormatted))
        #expect(item.price.description != lifetime.priceFormatted)
        #expect(item.priceDescription == nil)
        #expect(!item.priceDescripionAccented)
    }

    @Test func zeroDecimalCurrencyMonthlyPriceHasNoFractionDigits() throws {
        let item = try #require(factory.item(product: product(period: .annually, price: 29999, currency: "JPY"), offerWasUsed: false, monthlyPrice: 3000))

        let monthly = (Decimal(29999) / 12).formatted(.currency(code: "JPY"))
        #expect(monthly.filter(\.isNumber) == "2500")

        let description = try #require(item.priceDescription).description
        #expect(description.contains(monthly))
    }

    @Test func subscriptionWithoutPeriodIsSkipped() {
        let item = factory.item(product: product(period: nil, price: Self.monthlyPrice), offerWasUsed: false, monthlyPrice: Self.monthlyPrice)

        #expect(item == nil)
    }
}
