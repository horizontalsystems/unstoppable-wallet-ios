import UIKit
import SnapKit
import ThemeKit

class SwapValueView: UIView {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    public init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
        }
        titleLabel.font = .subhead2
        titleLabel.textColor = .themeGray
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        valueLabel.font = .subhead2
        valueLabel.textColor = .themeGray
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func set(title: String?) {
        titleLabel.text = title
    }

    func set(value: String?) {
        valueLabel.text = value
    }

}
