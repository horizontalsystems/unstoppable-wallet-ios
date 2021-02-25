import UIKit
import ThemeKit
import SnapKit

class MultiTextMetricsView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let valueChangeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(CGFloat.margin16)
        }

        titleLabel.font = .caption
        titleLabel.textColor = .themeGray

        let separator = UIView()
        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin4)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separator.backgroundColor = .themeSteel10

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(separator.snp.bottom).offset(CGFloat.margin8)
        }

        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.font = .subhead1
        valueLabel.textColor = .themeBran

        addSubview(valueChangeLabel)
        valueChangeLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin4)
            maker.centerY.equalTo(valueLabel)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        valueChangeLabel.font = .caption
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    public var value: String? {
        get { valueLabel.text }
        set { valueLabel.text = newValue }
    }

    public var valueChange: String? {
        get { valueChangeLabel.text }
        set { valueChangeLabel.text = newValue }
    }

    public var valueChangeColor: UIColor {
        get { valueChangeLabel.textColor }
        set { valueChangeLabel.textColor = newValue }
    }

}
