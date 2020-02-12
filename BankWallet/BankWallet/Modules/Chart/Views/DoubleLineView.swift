import UIKit
import SnapKit

class DoubleLineView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(titleColor: UIColor = .themeLeah, titleFont: UIFont = .caption, subtitleColor: UIColor = .themeGray, subtitleFont: UIFont = .micro, marginBetween: CGFloat = 3) {
        super.init(frame: .zero)

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(marginBetween)
        }

        titleLabel.textColor = titleColor
        titleLabel.font = titleFont
        subtitleLabel.textColor = subtitleColor
        subtitleLabel.font = subtitleFont
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(title: String?, subtitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

}
