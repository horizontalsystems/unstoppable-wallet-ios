import UIKit
import SnapKit

class LeftCoinCellView: UIView {
    private let coinImageView = CoinIconImageView()
    private let titleLabel = UILabel()
    private let coinLabel = UILabel()
    private let blockchainBadgeView = BadgeView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(coinImageView)
        coinImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinImageView.snp.trailing).offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(10)
            maker.trailing.equalToSuperview().inset(CGFloat.margin1x)
        }

        titleLabel.textColor = .themeOz
        titleLabel.font = .body

        addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel)
            maker.bottom.equalToSuperview().inset(CGFloat.margin2x)
        }

        coinLabel.textColor = .themeGray
        coinLabel.font = .subhead2

        addSubview(blockchainBadgeView)
        blockchainBadgeView.snp.makeConstraints { maker in
            maker.leading.equalTo(coinLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.centerY.equalTo(coinLabel.snp.centerY)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(coinTitle: String, coinCode: String, blockchainType: String?, showIcon: Bool = true) {
        if showIcon {
            coinImageView.isHidden = false
            coinImageView.bind(image: UIImage(named: "\(coinCode.lowercased())"))
            titleLabel.snp.remakeConstraints { maker in
                maker.leading.equalTo(coinImageView.snp.trailing).offset(CGFloat.margin4x)
                maker.top.equalToSuperview().offset(10)
                maker.trailing.equalToSuperview().inset(CGFloat.margin1x)
            }
        } else {
            coinImageView.isHidden = true
            titleLabel.snp.remakeConstraints { maker in
                maker.leading.equalToSuperview().offset(CGFloat.margin4x)
                maker.top.equalToSuperview().offset(10)
                maker.trailing.equalToSuperview().inset(CGFloat.margin1x)
            }
        }

        titleLabel.text = coinTitle
        coinLabel.text = coinCode

        if let blockchainType = blockchainType {
            blockchainBadgeView.isHidden = false
            blockchainBadgeView.set(text: blockchainType)
        } else {
            blockchainBadgeView.isHidden = true
        }
    }

}
