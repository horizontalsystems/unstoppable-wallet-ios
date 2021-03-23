import XRatesKit
import CoinKit

class CoinInvestorsViewModel {
    private let fundCategories: [CoinFundCategory]

    init(fundCategories: [CoinFundCategory]) {
        self.fundCategories = fundCategories
    }

    var title: String {
        "coin_page.funds_invested".localized
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
