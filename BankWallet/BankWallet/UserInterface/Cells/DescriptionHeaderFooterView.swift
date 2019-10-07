import UIKit
import SnapKit

class DescriptionHeaderFooterView: UITableViewHeaderFooterView {
    private let descriptionView = DescriptionView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        descriptionView.bind(text: text)
    }

}

extension DescriptionHeaderFooterView {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        DescriptionView.height(containerWidth: containerWidth, text: text)
    }

}
