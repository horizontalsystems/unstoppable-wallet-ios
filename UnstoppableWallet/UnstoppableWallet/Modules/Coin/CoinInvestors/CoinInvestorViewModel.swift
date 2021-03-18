import XRatesKit
import CoinKit

class CoinInvestorsViewModel {
    private let coinCode: String
    private let fundCategories: [CoinFundCategory]

    init(coinCode: String, fundCategories: [CoinFundCategory]) {
        self.coinCode = coinCode
        self.fundCategories = fundCategories
    }

    var title: String {
        "coin_page.investors".localized(coinCode)
    }

    var sectionViewItems: [SectionViewItem] {
        fundCategories.map { fundCategory in
            SectionViewItem(
                    title: fundCategory.name,
                    viewItems: fundCategory.funds.map { fund in
                        ViewItem(title: fund.name, url: fund.url)
                    }
            )
        }
    }

}

extension CoinInvestorsViewModel {

    struct SectionViewItem {
        let title: String
        let viewItems: [ViewItem]
    }

    struct ViewItem {
        let title: String
        let url: String
    }

}
