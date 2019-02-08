import UIKit
import SnapKit

class BalanceEditCell: UITableViewCell {
    var onTap: (() -> ())?

    var editButton = UIButton()
    var editImageView = UIImageView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        editButton.cornerRadius = BalanceTheme.editButtonSideSize / 2
        editButton.layer.borderWidth = 1
        editButton.layer.borderColor = BalanceTheme.editButtonStrokeColor.cgColor
        editButton.setBackgroundColor(color: BalanceTheme.editButtonBackground, forState: .normal)
        editButton.setBackgroundColor(color: BalanceTheme.editButtonSelectedBackground, forState: .selected)
        editButton.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        contentView.addSubview(editButton)
        editButton.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(BalanceTheme.editButtonSideSize)
        }
        editImageView.image = UIImage(named: "Edit Coins Icon")
        contentView.addSubview(editImageView)
        editImageView.snp.makeConstraints { maker in
            maker.center.equalTo(self.editButton)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func didTap() {
        onTap?()
    }

}
