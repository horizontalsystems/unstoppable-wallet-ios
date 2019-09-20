import UIKit
import SnapKit
import HUD

class RateListChangingCellView: UIView {
    private let rateLabel = UILabel()
    private let diffLabel = UILabel()

    private let processSpinner = HUDProgressView(
            strokeLineWidth: CGFloat.cornerRadius2,
            radius: CGFloat.cornerRadius8 - CGFloat.cornerRadius2,
            strokeColor: .appGray
    )

    override init(frame: CGRect) {
        super.init(frame: frame)

        rateLabel.font = .cryptoSubhead1
        rateLabel.textAlignment = .right
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(10)
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        diffLabel.font = .cryptoHeadline2
        diffLabel.textAlignment = .right
        diffLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        diffLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(diffLabel)
        diffLabel.snp.makeConstraints { maker in
            maker.top.equalTo(rateLabel.snp.bottom).offset(CGFloat.margin1x)
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        addSubview(processSpinner)
        processSpinner.snp.makeConstraints { maker in
            maker.left.greaterThanOrEqualToSuperview()
            maker.bottom.equalToSuperview().inset(10)
            maker.right.equalToSuperview().inset(CGFloat.margin4x + CGFloat.margin1x)
            maker.size.equalTo(CGFloat.cornerRadius8 * 2)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(loading: Bool, rate: String?, rateColor: UIColor, diff: String?, diffColor: UIColor) {
        rateLabel.isHidden = loading
        diffLabel.isHidden = loading
        processSpinner.isHidden = !loading
        if loading {
            processSpinner.startAnimating()
        } else {
            processSpinner.stopAnimating()
        }
        rateLabel.text = rate
        rateLabel.textColor = rateColor

        diffLabel.text = diff
        diffLabel.textColor = diffColor
    }

}
