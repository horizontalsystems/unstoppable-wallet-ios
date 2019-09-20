import UIKit
import SnapKit

class DisclosureCellView: UIView {
    private let imageView = UIImageView(image: UIImage(named: "Disclosure Indicator"))

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.leading.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
