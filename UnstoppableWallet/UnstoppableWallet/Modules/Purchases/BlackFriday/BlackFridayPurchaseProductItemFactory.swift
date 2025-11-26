import Foundation
import SwiftUI

class BlackFridayPurchaseProductItemFactory: PurchaseProductItemFactory {
    private func getDiscountPercentage(for product: PurchaseManager.ProductData) -> Int {
        switch product.type {
        case .lifetime:
            return 10
        case .subscription:
            guard let period = product.period else { return 0 }
            switch period {
            case .annually: return 50
            case .monthly: return 20
            }
        }
    }

    private func calculateOriginalPrice(currentPrice: Decimal, discountPercentage: Int) -> Decimal {
        let discountMultiplier = Decimal(100 - discountPercentage) / 100
        return (currentPrice / discountMultiplier).rounded(decimal: 1)
    }

    private func formatPrice(_ price: Decimal, formatStyle: Decimal.FormatStyle.Currency) -> String {
        price.formatted(formatStyle)
    }

    private func createPriceDescription(
        originalPrice: Decimal,
        formatStyle: Decimal.FormatStyle.Currency,
        periodText: String?
    ) -> AttributedString {
        let formattedPrice = formatPrice(originalPrice, formatStyle: formatStyle)
        var formatted = AttributedString(formattedPrice)
        formatted.strikethroughStyle = .single

        if let periodText {
            let periodAttr = AttributedString(" " + periodText)
            formatted.append(periodAttr)
        }

        return formatted
    }

    override func item(product: PurchaseManager.ProductData, offerWasUsed: Bool, monthlyPrice _: Decimal?) -> Item? {
        var title: String
        var discountBadge: String?
        var badgeType: BadgeType = .standart

        let currentPrice = product.priceFormatted
        let descriptionPeriod: String

        let introductoryOfferType: PurchaseManager.IntroductoryOfferType
        if offerWasUsed {
            introductoryOfferType = .none
        } else {
            introductoryOfferType = .init(product.introductoryOffer)
        }

        let discountPercentage = getDiscountPercentage(for: product)

        let originalPrice = calculateOriginalPrice(
            currentPrice: product.price,
            discountPercentage: discountPercentage
        )

        switch product.type {
        case .lifetime:
            title = "purchase.period.onetime".localized

            discountBadge = "-\(discountPercentage)%"
            descriptionPeriod = "purchase.black_friday.period.lifetime".localized
        case .subscription:
            guard let period = product.period else {
                return nil
            }

            title = period.title

            if discountPercentage > 0 {
                discountBadge = "-\(discountPercentage)%"
            }

            switch period {
            case .monthly:
                badgeType = .standart
                discountBadge = "-\(discountPercentage)%"
                descriptionPeriod = "purchase.black_friday.period.per_month".localized
            case .annually:
                badgeType = .blackFriday
                descriptionPeriod = "purchase.black_friday.period.per_year".localized
                discountBadge = "premium.black_friday.discount.save".localized + " \(discountPercentage)%"
            }
        }

        let priceDescription = createPriceDescription(
            originalPrice: originalPrice,
            formatStyle: product.priceFormatStyle,
            periodText: descriptionPeriod
        )

        return Item(
            product: product,
            title: title,
            discountBadge: discountBadge,
            badgeType: badgeType,
            price: currentPrice,
            priceDescription: priceDescription,
            priceDescripionAccented: false,
            introductoryOfferType: introductoryOfferType,
            originalPrice: originalPrice,
            discountPercentage: discountPercentage
        )
    }
}

extension BlackFridayPurchaseProductItemFactory {
    enum BadgeType {
        case standart
        case blackFriday
    }

    class Item: PurchaseProductItemFactory.Item {
        let originalPrice: Decimal
        let discountPercentage: Int
        let badgeType: BadgeType

        var attributedDescription: AttributedString? {
            priceDescription as? AttributedString
        }

        init(product: PurchaseManager.ProductData,
             title: String,
             discountBadge: String?,
             badgeType: BadgeType = .standart,
             price: CustomStringConvertible,
             priceDescription: AttributedString?,
             priceDescripionAccented: Bool,
             introductoryOfferType: PurchaseManager.IntroductoryOfferType,
             originalPrice: Decimal,
             discountPercentage: Int)
        {
            self.originalPrice = originalPrice
            self.discountPercentage = discountPercentage
            self.badgeType = badgeType

            super.init(
                product: product,
                title: title,
                discountBadge: discountBadge,
                price: price,
                priceDescription: priceDescription,
                priceDescripionAccented: priceDescripionAccented,
                introductoryOfferType: introductoryOfferType
            )
        }
    }
}
