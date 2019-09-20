import UIKit

class RateListHeaderView: UITableViewHeaderFooterView {
    private let titleLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        titleLabel.textColor = .appOz
        titleLabel.font = .cryptoTitle1
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin6x)
            maker.top.equalToSuperview().offset(CGFloat.margin6x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(title: String) {
        titleLabel.text = title
    }

    static func height(forContainerWidth containerWidth: CGFloat, text: String) -> CGFloat {
        return text.height(forContainerWidth: containerWidth, font: .cryptoTitle1) + CGFloat.margin6x + CGFloat.margin4x
    }

}
