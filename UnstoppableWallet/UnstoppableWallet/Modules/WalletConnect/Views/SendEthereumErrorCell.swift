import UIKit

class SendEthereumErrorCell: UITableViewCell {
    private static let font: UIFont = .subhead2
    private static let padding: CGFloat = .margin4x

    private let errorLabel = UILabel()
    var isVisible = true

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(SendEthereumErrorCell.padding)
        }

        errorLabel.numberOfLines = 0
        errorLabel.font = SendEthereumErrorCell.font
        errorLabel.textColor = .themeLucian
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        errorLabel.text = text
    }

    func cellHeight(width: CGFloat) -> CGFloat {
        guard let text = errorLabel.text else {
            return 0
        }

        return isVisible ? Self.height(text: text, containerWidth: width) : 0
    }

}

extension SendEthereumErrorCell {

    static func height(text: String, containerWidth: CGFloat) -> CGFloat {
        text.height(forContainerWidth: containerWidth - SendEthereumErrorCell.padding * 2, font: SendEthereumErrorCell.font) + SendEthereumErrorCell.padding
    }

}
