import UIKit
import SnapKit

class RateDiffView: UIView {
    private let imageView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalTo(imageView.snp.trailing).offset(CGFloat.margin1x)
            maker.top.trailing.bottom.equalToSuperview()
        }

        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var font: UIFont {
        get {
            label.font
        }
         set {
             label.font = newValue
         }
    }

    func set(value: Decimal?, highlightText: Bool = true) {
        guard let value = value else {
            label.text = nil
            imageView.image = nil
            return
        }
        let color: UIColor = value.isSignMinus ? .themeLucian : .themeRemus
        let imageName = value.isSignMinus ? "arrow_medium_2_down_20" : "arrow_medium_2_up_20"

        imageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = color

        let formattedDiff = RateDiffView.formatter.string(from: abs(value) as NSNumber)

        label.textColor = highlightText ? color : .themeGray
        label.text = formattedDiff.map { "\($0)%" }
    }

}

extension RateDiffView {

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

}
