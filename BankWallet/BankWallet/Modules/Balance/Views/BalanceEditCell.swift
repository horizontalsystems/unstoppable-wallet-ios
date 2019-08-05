import UIKit
import SnapKit
import UIExtensions

class BalanceEditCell: UITableViewCell {
    var onTap: (() -> ())?

    let wrapperView = RespondView()
    let titleLabel = UILabel()
    let editImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.height.equalTo(BalanceTheme.editButtonSideSize)
        }

        wrapperView.addSubview(editImageView)
        editImageView.cornerRadius = BalanceTheme.editButtonSideSize / 2
        editImageView.layer.borderWidth = 1
        editImageView.layer.borderColor = BalanceTheme.editButtonStrokeColor.cgColor
        editImageView.backgroundColor = BalanceTheme.editButtonBackground
        editImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }
        editImageView.image = UIImage(named: "Edit Coins Icon")?.tinted(with: UIColor.cryptoGreen)
        editImageView.contentMode = .center

        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(editImageView.snp.trailing).offset(BalanceTheme.cellBigMargin)
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }
        titleLabel.text = "balance.add_coins".localized
        titleLabel.font = BalanceTheme.editTitleFont
        titleLabel.textColor = BalanceTheme.editTitleColor

        wrapperView.handleTouch = { [weak self] in
            self?.didTap()
        }
        wrapperView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func didTap() {
        onTap?()
    }

}

extension BalanceEditCell: RespondViewDelegate {
    public var touchTransparent: Bool {
        return  false
    }

    public func touchBegan() {
        editImageView.backgroundColor = BalanceTheme.editButtonSelectedBackground
        titleLabel.textColor = BalanceTheme.editTitleSelectedColor

    }

    public func touchEnd() {
        editImageView.backgroundColor = BalanceTheme.editButtonBackground
        titleLabel.textColor = BalanceTheme.editTitleColor
    }
}
