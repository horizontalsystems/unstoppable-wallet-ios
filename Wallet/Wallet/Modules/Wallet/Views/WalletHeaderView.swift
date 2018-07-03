import UIKit
import SnapKit

class WalletHeaderView: UIView {

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
        backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: WalletTheme.blurStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        addSubview(blurView)
        blurView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        preservesSuperviewLayoutMargins = true

        addSubview(amountLabel)
        amountLabel.textColor = WalletTheme.amountColor
        amountLabel.font = WalletTheme.amountFont
        amountLabel.preservesSuperviewLayoutMargins = true

        amountLabel.snp.makeConstraints { maker in
            maker.leadingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.top.equalToSuperview().offset(WalletTheme.cellSmallMargin)
        }
    }

    func bind(amount: String?) {
        amountLabel.text = amount
    }

}
