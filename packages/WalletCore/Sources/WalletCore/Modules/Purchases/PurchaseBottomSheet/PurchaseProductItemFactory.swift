import Foundation

class PurchaseProductItemFactory {
    func item(product: PurchaseManager.ProductData, offerWasUsed: Bool, monthlyPrice: Decimal?) -> Item? {
        var title: String
        var discountBadge: String?

        var price = product.priceFormatted
        var priceDescription: String?
        var priceDescripionAccented: Bool

        let introductoryOfferType: PurchaseManager.IntroductoryOfferType
        if offerWasUsed {
            introductoryOfferType = .none
        } else {
            introductoryOfferType = .init(product.introductoryOffer)
        }

        switch product.type {
        case .lifetime:
            title = "purchase.period.onetime".localized
            discountBadge = nil

            // one string, so each language can place the price where its word order needs it
            price = "purchase.period.onetime.price".localized(product.priceFormatted)
            priceDescription = nil
            priceDescripionAccented = false
        case .subscription:
            guard let period = product.period else {
                return nil
            }

            title = period.title
            switch period {
            case .monthly:
                discountBadge = nil

                priceDescription = nil
                priceDescripionAccented = false
            case .annually:
                let realMonthlyPrice = product.price / 12

                if let monthlyPrice, monthlyPrice > 0 {
                    let discountPrecentage = ((monthlyPrice - realMonthlyPrice) / monthlyPrice) * 100
                    discountBadge = ["purchase.period.save".localized.uppercased(), "\(discountPrecentage.rounded(decimal: 0))%"].joined(separator: " ")

                    priceDescription = "(\(realMonthlyPrice.formatted(product.priceFormatStyle)) / \("purchase.period.month".localized))"
                    priceDescripionAccented = true
                } else {
                    discountBadge = nil
                    priceDescription = nil
                    priceDescripionAccented = false
                }
            }
        }

        return .init(
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

extension PurchaseProductItemFactory {
    class Item: Hashable, Equatable {
        let product: PurchaseManager.ProductData
        let title: String
        let discountBadge: String?
        let price: CustomStringConvertible
        let priceDescription: CustomStringConvertible?
        let priceDescripionAccented: Bool
        let introductoryOfferType: PurchaseManager.IntroductoryOfferType

        init(product: PurchaseManager.ProductData,
             title: String,
             discountBadge: String?,
             price: CustomStringConvertible,
             priceDescription: CustomStringConvertible?,
             priceDescripionAccented: Bool,
             introductoryOfferType: PurchaseManager.IntroductoryOfferType)
        {
            self.product = product
            self.title = title
            self.discountBadge = discountBadge
            self.price = price
            self.priceDescription = priceDescription
            self.priceDescripionAccented = priceDescripionAccented
            self.introductoryOfferType = introductoryOfferType
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(product.id)
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.product.id == rhs.product.id
        }
    }
}
