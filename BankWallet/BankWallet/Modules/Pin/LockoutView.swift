import UIKit
import SnapKit

class LockoutView: UIView {
    let lockIcon = UIImageView(image: UIImage(named: "Lockout Icon"))
    let infoLabel = UILabel()

    init() {
        super.init(frame: .zero)
        backgroundColor = AppTheme.controllerBackground

        addSubview(lockIcon)
        lockIcon.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().multipliedBy(0.66)
        }
        addSubview(infoLabel)
        infoLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.lockIcon.snp.bottom).offset(PinTheme.lockoutLabelTopMargin)
            maker.leading.equalTo(self.snp.leading).offset(PinTheme.lockoutLabelSideMargin)
            maker.trailing.equalTo(self.snp.trailing).offset(-PinTheme.lockoutLabelSideMargin)
        }
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        infoLabel.font = PinTheme.lockoutLabelFont
        infoLabel.textColor = PinTheme.lockoutLabelColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func show(expirationDate: Date) {
        isHidden = false
        infoLabel.text = "unlock_pin.lockout_blocked_until".localized(DateHelper.instance.formatLockoutExpirationDate(from: expirationDate))
    }

    func hide() {
        isHidden = true
    }

}
