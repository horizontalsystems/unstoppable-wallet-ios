import UIKit
import SnapKit

class BottomDescriptionHeaderFooterView: UITableViewHeaderFooterView {
    private let descriptionView = BottomDescriptionView()

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

extension BottomDescriptionHeaderFooterView {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        BottomDescriptionView.height(containerWidth: containerWidth, text: text)
    }

}
