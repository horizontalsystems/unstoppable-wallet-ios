import UIKit
import SnapKit

class LeftCoinNameCellView: UIView {
    private let titleLabel = UILabel()
    private let coinLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String, code: String) {
        titleLabel.text = title
        coinLabel.text = code
    }

}
