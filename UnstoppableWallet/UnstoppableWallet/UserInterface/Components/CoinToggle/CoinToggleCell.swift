import UIKit
import SnapKit
import ThemeKit

class CoinToggleCell: ThemeCell {
    private let leftCoinView = LeftCoinCellView()
    private let toggleView = UISwitch()
    private let addImageView = UIImageView()

    private var onToggle: ((Bool) -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(leftCoinView)
        leftCoinView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        contentView.addSubview(toggleView)
        toggleView.snp.makeConstraints { maker in
            maker.leading.equalTo(leftCoinView.snp.trailing)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        toggleView.setContentCompressionResistancePriority(.required, for: .horizontal)
        toggleView.tintColor = .themeSteel20
        toggleView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)

        contentView.addSubview(addImageView)
        addImageView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        addImageView.image = UIImage(named: "Edit Coins Icon")?.withRenderingMode(.alwaysTemplate)
        addImageView.tintColor = .themeGray
    }

    @objc func switchChanged() {
        onToggle?(toggleView.isOn)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: CoinToggleViewModel.ViewItem, last: Bool, onToggle: ((Bool) -> ())? = nil) {
        let coin = viewItem.coin

        leftCoinView.bind(coinTitle: coin.title, coinCode: coin.code, blockchainType: coin.type.blockchainType)

        switch viewItem.state {
        case .toggleHidden:
            super.bind(last: last)

            addImageView.isHidden = false
            toggleView.isHidden = true
            selectionStyle = .default
        case .toggleVisible(let enabled):
            super.bind(last: last)

            addImageView.isHidden = true
            toggleView.isHidden = false
            toggleView.setOn(enabled, animated: false)
            selectionStyle = .none
        }

        self.onToggle = onToggle
    }

    func setToggleOff() {
        toggleView.setOn(false, animated: true)
    }

}
