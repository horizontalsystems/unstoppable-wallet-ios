import UIKit
import SnapKit

class TopDescriptionView: UITableViewHeaderFooterView {
    private let label = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        label.numberOfLines = 0
        label.font = .cryptoSubhead2
        label.textColor = .cryptoGray
        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        label.text = text
    }

}

extension TopDescriptionView {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = ceil(text.height(forContainerWidth: containerWidth - 2 * CGFloat.margin6x, font: .cryptoSubhead2))
        return textHeight + CGFloat.margin6x + CGFloat.margin3x
    }

}
