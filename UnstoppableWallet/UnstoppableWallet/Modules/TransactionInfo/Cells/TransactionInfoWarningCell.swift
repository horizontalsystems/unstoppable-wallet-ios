import UIKit
import ThemeKit
import ComponentKit

class TransactionInfoWarningCell: BaseThemeCell {
    private static let imageViewLeadingMargin: CGFloat = .margin4x
    private static let imageViewSize: CGFloat = 20
    private static let labelLeadingMargin: CGFloat = .margin4x
    private static let labelVerticalMargin: CGFloat = 13.5
    private static let labelFont: UIFont = .subhead2
    private static let buttonWidth: CGFloat = 24 + 2 * .margin4x

    private let iconImageView = UIImageView()
    private let label = UILabel()
    private let button = ThemeButton()

    private var onTapButton: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoWarningCell.imageViewLeadingMargin)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.size.equalTo(TransactionInfoWarningCell.imageViewSize)
        }

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(TransactionInfoWarningCell.labelLeadingMargin)
            maker.top.equalToSuperview().offset(TransactionInfoWarningCell.labelVerticalMargin)
        }

        label.numberOfLines = 0
        label.font = TransactionInfoWarningCell.labelFont
        label.textColor = .themeGray

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.equalTo(label.snp.trailing)
            maker.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(TransactionInfoWarningCell.buttonWidth)
        }

        button.setImageTintColor(.themeJacob, for: .normal)
        button.setImage(UIImage(named: "circle_information_20")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(_onTapButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapButton() {
        onTapButton?()
    }

    func bind(image: UIImage?, text: String, onTapButton: @escaping () -> ()) {
        iconImageView.image = image
        label.text = text

        self.onTapButton = onTapButton
    }

}

extension TransactionInfoWarningCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textWidth = containerWidth - imageViewLeadingMargin - imageViewSize - labelLeadingMargin - buttonWidth
        let textHeight = text.height(forContainerWidth: textWidth, font: labelFont)

        return textHeight + 2 * labelVerticalMargin
    }

}
