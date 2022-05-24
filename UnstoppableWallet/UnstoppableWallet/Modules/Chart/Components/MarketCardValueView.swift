import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class MarketCardValueView: UIView {
    private static let font: UIFont = .subhead1
    static let height: CGFloat = ceil(MarketCardValueView.font.lineHeight)

    private let valueLabel = UILabel()
    private let diffLabel = DiffLabel()

    init() {
        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(Self.height)
        }

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.bottom.top.equalToSuperview()
        }

        valueLabel.font = Self.font

        addSubview(diffLabel)
        diffLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin8)
            maker.centerY.equalTo(valueLabel)
        }

        diffLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        diffLabel.textAlignment = .right
        diffLabel.font = Self.font
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    var value: String? {
        get { valueLabel.text }
        set { valueLabel.text = newValue }
    }

    var valueColor: UIColor {
        get { valueLabel.textColor }
        set { valueLabel.textColor = newValue }
    }

    var diff: String? {
        get { diffLabel.text }
        set { diffLabel.text = newValue }
    }

    var diffColor: UIColor {
        get { diffLabel.textColor }
        set { diffLabel.textColor = newValue }
    }

}
