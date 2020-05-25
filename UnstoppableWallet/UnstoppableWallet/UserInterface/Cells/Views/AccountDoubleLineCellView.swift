import UIKit

class AccountDoubleLineCellView: UIView {
    private static let titleFont: UIFont = .headline2
    private static let subtitleFont: UIFont = .subhead2
    private static let verticalMargin: CGFloat = .margin2x

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = AccountDoubleLineCellView.titleFont
        titleLabel.textColor = .themeOz

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
        }

        subtitleLabel.font = AccountDoubleLineCellView.subtitleFont
        subtitleLabel.textColor = .themeGray
        subtitleLabel.numberOfLines = 0

        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(AccountDoubleLineCellView.verticalMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

}

extension AccountDoubleLineCellView {

    static func height(containerWidth: CGFloat, title: String, subtitle: String) -> CGFloat {
        let titleHeight = title.height(forContainerWidth: containerWidth, font: AccountDoubleLineCellView.titleFont)
        let subtitleHeight = subtitle.height(forContainerWidth: containerWidth, font: AccountDoubleLineCellView.subtitleFont)

        return titleHeight + AccountDoubleLineCellView.verticalMargin + subtitleHeight
    }

}
