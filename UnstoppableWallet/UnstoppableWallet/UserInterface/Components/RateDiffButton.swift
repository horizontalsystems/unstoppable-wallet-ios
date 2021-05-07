import UIKit
import SnapKit

class RateDiffButton: UIButton {
    private let iconImageView = UIImageView()
    private let separatorView = UIView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        layer.borderColor = UIColor.themeSteel20.cgColor
        layer.borderWidth = .heightOneDp
        layer.cornerRadius = .cornerRadius2x

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.size.equalTo(20)
        }

        iconImageView.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin2x)
            maker.width.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel20

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalTo(separatorView.snp.trailing)
            maker.top.trailing.bottom.equalToSuperview()
        }

        label.textAlignment = .center
        label.font = .captionSB

        updateUITheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateUITheme()
    }

    private func updateUITheme() {
        setBackgroundColor(color: .themeLawrence, forState: .normal)
        setBackgroundColor(color: .themeLawrencePressed, forState: .highlighted)
    }

    func show(value: Decimal, dimmed: Bool) {
        let color: UIColor = dimmed ? .themeGray50 : (value.isSignMinus ? .themeLucian : .themeRemus)
        let imageName = value.isSignMinus ? "arrow_medium_2_down_20" : "arrow_medium_2_up_20"

        iconImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = color

        let formattedDiff = RateDiffButton.formatter.string(from: abs(value) as NSNumber)

        label.textColor = dimmed ? .themeGray50 : .themeLeah
        label.text = formattedDiff.map { "\($0)%" }
    }

    func showNotAvailable() {
        iconImageView.image = UIImage(named: "Up")?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = .themeGray50
        label.textColor = .themeGray50
        label.text = "n/a"
    }

}

extension RateDiffButton {

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

}
