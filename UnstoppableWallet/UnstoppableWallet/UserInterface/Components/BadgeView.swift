import UIKit
import SnapKit

class BadgeView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        snp.makeConstraints { maker in
            maker.height.equalTo(15)
        }

        layer.cornerRadius = .cornerRadius1x
        backgroundColor = .themeJeremy

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin1x)
            maker.centerY.equalToSuperview()
        }

        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.textColor = .themeGray
        label.font = .microSB
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(text: String?) {
        label.text = text
    }

}
