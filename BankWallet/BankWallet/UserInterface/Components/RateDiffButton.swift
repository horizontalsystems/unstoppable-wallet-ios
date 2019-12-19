import UIKit
import SnapKit

class RateDiffButton: UIButton {
    private let iconImageView = UIImageView()
    private let separatorView = UIView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        layer.borderColor = UIColor.appSteel20.cgColor
        layer.borderWidth = .heightOnePixel
        layer.cornerRadius = .cornerRadius4

        setBackgroundColor(color: .appLawrence, forState: .normal)
        setBackgroundColor(color: .appLawrencePressed, forState: .highlighted)

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin1x)
            maker.centerY.equalToSuperview()
        }

        iconImageView.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(CGFloat.margin1x)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin1x)
            maker.width.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .appSteel20

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalTo(separatorView.snp.trailing)
            maker.top.trailing.bottom.equalToSuperview()
        }

        label.textAlignment = .center
        label.font = .appCaption
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(value: Decimal, dimmed: Bool) {
        let color: UIColor = dimmed ? .appGray50 : (value.isSignMinus ? .appLucian : .cryptoGreen)
        let imageName = value.isSignMinus ? "Down" : "Up"

        iconImageView.image = UIImage(named: imageName)?.tinted(with: color)

        let formattedDiff = RateDiffButton.formatter.string(from: abs(value) as NSNumber)

        label.textColor = dimmed ? .appGray50 : .appGray
        label.text = formattedDiff.map { "\($0)%" }
    }

    func showNotAvailable() {
        iconImageView.image = UIImage(named: "Up")?.tinted(with: .appGray50)
        label.textColor = .appGray50
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
