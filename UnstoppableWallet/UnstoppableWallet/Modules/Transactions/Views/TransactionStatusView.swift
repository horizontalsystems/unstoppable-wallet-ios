import UIKit
import SnapKit

class TransactionStatusView: UIView {
    private var imageView = UIImageView()
    private var label = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalTo(imageView.snp.trailing).offset(CGFloat.margin16)
            maker.centerY.equalTo(imageView)
            maker.trailing.equalToSuperview()
        }
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textColor = .themeGray
        label.font = .subhead2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(image: UIImage?, imageTintColor: UIColor, status: String) {
        imageView.image = image
        imageView.tintColor = imageTintColor
        label.text = status
    }

}
