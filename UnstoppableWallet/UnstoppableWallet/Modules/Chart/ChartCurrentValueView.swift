import UIKit

class ChartCurrentValueView: UIView {
    private let valueLabel = UILabel()
    private let diffLabel = DiffLabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        valueLabel.font = .title3
        valueLabel.textColor = .themeLeah
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        addSubview(diffLabel)

        diffLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin8)
            maker.top.bottom.equalToSuperview()
        }

        diffLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        diffLabel.font = .subhead1

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.leading.equalTo(diffLabel.snp.trailing).offset(CGFloat.margin8)
            maker.centerY.equalToSuperview()
        }

        titleLabel.font = .caption
        titleLabel.textColor = .themeGray
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension ChartCurrentValueView {

    var value: String? {
        get { valueLabel.text }
        set { valueLabel.text = newValue }
    }

    var diff: String? {
        get { diffLabel.text }
        set { diffLabel.text = newValue }
    }

    var diffColor: UIColor! {
        get { diffLabel.textColor }
        set { diffLabel.textColor = newValue }
    }

    func set(diff: Decimal?) {
        diffLabel.set(value: diff)
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

}
