import UIKit
import SnapKit

class BalanceHeaderView: UIView {

    private let amountLabel = UILabel()
    private let statsSwitchButton = UIButton()

    var onStatsSwitch: (() -> ())?

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

        addSubview(statsSwitchButton)
        statsSwitchButton.isHidden = true
        statsSwitchButton.setImage(UIImage(named: "Stats Switch Button")?.tinted(with: BalanceTheme.headerTintColorNormal), for: .normal)
        statsSwitchButton.setImage(UIImage(named: "Stats Switch Button")?.tinted(with: BalanceTheme.headerTintColor), for: .selected)
        statsSwitchButton.setImage(UIImage(named: "Stats Switch Button")?.tinted(with: BalanceTheme.headerTintColorSelected), for: .highlighted)
        statsSwitchButton.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.width.equalTo(BalanceTheme.statButtonWidth)
        }
        statsSwitchButton.addTarget(self, action: #selector(onSwitch), for: .touchUpInside)

        addSubview(amountLabel)
        amountLabel.font = BalanceTheme.amountFont
        amountLabel.preservesSuperviewLayoutMargins = true

        amountLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(AppTheme.viewMargin)
            maker.top.equalToSuperview().offset(BalanceTheme.cellSmallMargin)
        }
    }

    func bind(amount: String?, upToDate: Bool, statsIsOn: Bool) {
        amountLabel.text = amount
        amountLabel.textColor = upToDate ? BalanceTheme.amountColor : BalanceTheme.amountColorSyncing
        statsSwitchButton.isSelected = statsIsOn
    }

    @objc func onSwitch() {
        onStatsSwitch?()
    }

    func setStatSwitch(hidden: Bool) {
        statsSwitchButton.isHidden = hidden
    }

}
