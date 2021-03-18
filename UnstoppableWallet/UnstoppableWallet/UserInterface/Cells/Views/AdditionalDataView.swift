import UIKit

class AdditionalDataView: UIView {
    static let height: CGFloat = 29

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        snp.makeConstraints { maker in
            maker.height.equalTo(AdditionalDataView.height)
        }

        backgroundColor = .clear

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.top.equalToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.textColor = .themeGray
        titleLabel.font = .subhead2

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview()
        }

        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        valueLabel.textColor = .themeGray
        valueLabel.font = .subhead2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String?, value: String?) {
        titleLabel.text = title
        valueLabel.text = value
    }

    func clear() {
        titleLabel.text = nil
        valueLabel.text = nil
    }

    func setValue(color: UIColor) {
        valueLabel.textColor = color
    }

    func setTitle(color: UIColor) {
        titleLabel.textColor = color
    }

    func setValue(hidden: Bool) {
        valueLabel.isHidden = hidden
    }

    func set(hidden: Bool) {
        self.isHidden = hidden
        snp.updateConstraints { maker in
            maker.height.equalTo(hidden ? 0 : Self.height)
        }
        layoutIfNeeded()
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var value: String? {
        get { valueLabel.text }
        set { valueLabel.text = newValue }
    }

}
