import UIKit
import SnapKit

class BalanceHeaderView: UIView {

    let amountLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        backgroundColor = AppTheme.navigationBarBackgroundColor

        preservesSuperviewLayoutMargins = true

        addSubview(amountLabel)
        amountLabel.font = BalanceTheme.amountFont
        amountLabel.preservesSuperviewLayoutMargins = true

        amountLabel.snp.makeConstraints { maker in
            maker.leadingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.top.equalToSuperview().offset(BalanceTheme.cellSmallMargin)
        }
    }

    func bind(amount: String?, upToDate: Bool) {
        amountLabel.text = amount
        amountLabel.textColor = upToDate ? BalanceTheme.amountColor : BalanceTheme.amountColorSyncing
    }

}
