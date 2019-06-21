import UIKit
import SnapKit

class BalanceHeaderView: UIView {

    let amountLabel = UILabel()
    let sortView = UIView()
    let sortLabelButton = UIButton()
    let sortDirectionButton = UIButton()

    var onSortDirectionChange: (() -> ())?
    var onSortTypeChange: (() -> ())?

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

        addSubview(sortView)
        sortView.backgroundColor = BalanceTheme.headerSortBackground
        sortView.layer.cornerRadius = BalanceTheme.headerSortCornerRadius
        sortView.layer.borderColor = BalanceTheme.headerSortBorderColor.cgColor
        sortView.layer.borderWidth = BalanceTheme.headerSortBorderWidth
        sortView.snp.makeConstraints { maker in
            maker.trailingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.height.equalTo(BalanceTheme.headerSortHeight)
            maker.centerY.equalToSuperview()
        }

        sortView.addSubview(sortLabelButton)
        sortLabelButton.titleLabel?.font = BalanceTheme.sortLabelFont
        sortLabelButton.setTitleColor(BalanceTheme.sortLabelTextColor, for: .normal)
        sortLabelButton.setTitleColor(BalanceTheme.sortLabelSelectedTextColor, for: .highlighted)
        sortLabelButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BalanceTheme.headerHugeMargin)
        }
        sortLabelButton.addTarget(self, action: #selector(onSortTypeTap), for: .touchUpInside)

        sortView.addSubview(sortDirectionButton)
        sortDirectionButton.setImage(UIImage(named: "Sort Direction Down"), for: .normal)
        sortDirectionButton.snp.makeConstraints { maker in
            maker.leading.equalTo(self.sortLabelButton.snp.trailing)
            maker.trailing.equalToSuperview().offset(-BalanceTheme.headerTinyMargin)
            maker.top.bottom.equalToSuperview()
        }
        sortDirectionButton.addTarget(self, action: #selector(onSortDirectionTap), for: .touchUpInside)

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

    @objc func onSortTypeTap() {
        onSortTypeChange?()
    }

    @objc func onSortDirectionTap() {
        onSortDirectionChange?()
    }

}
