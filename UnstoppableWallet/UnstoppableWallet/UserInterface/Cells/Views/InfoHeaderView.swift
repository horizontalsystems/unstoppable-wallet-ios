import UIKit

class InfoHeaderView: UITableViewHeaderFooterView {
    private static let topPadding = CGFloat.margin6x
    private static let bottomPadding = CGFloat.margin3x
    private static let horizontalPadding = CGFloat.margin6x
    private static let font: UIFont = .headline2

    private let label = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(InfoHeaderView.horizontalPadding)
            maker.top.equalToSuperview().inset(InfoHeaderView.topPadding)
        }

        label.numberOfLines = 0
        label.font = InfoHeaderView.font
        label.textColor = .themeJacob
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        label.text = text
    }

}

extension InfoHeaderView {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font)
        return textHeight + topPadding + bottomPadding
    }

}
