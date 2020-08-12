import UIKit

class ChartCurrentRateView: UIView {
    private let rateLabel = UILabel()
    private let diffImageView = UIImageView()
    private let diffLabel = UILabel()

    private let alertButton = UIButton()

    private var onTap: (() -> ())?

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(rateLabel)
        rateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        rateLabel.font = .title3
        rateLabel.textColor = .themeOz
        rateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        addSubview(diffImageView)
        addSubview(diffLabel)

        diffLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(diffImageView.snp.trailing).offset(CGFloat.margin1x)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x + CGFloat.margin2x + 16)
        }
        diffImageView.snp.makeConstraints { maker in
            maker.leading.greaterThanOrEqualTo(rateLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.centerY.equalToSuperview()
        }

        diffImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        diffLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        diffLabel.font = .subhead1
        diffLabel.textColor = .themeLeah

        addSubview(alertButton)
        alertButton.snp.makeConstraints { maker in
            maker.leading.equalTo(diffImageView)
            maker.centerY.equalTo(diffLabel)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        alertButton.setImage(UIImage(named: "Notification Small Icon")?.tinted(with: .themeGray50), for: .highlighted)
        alertButton.contentHorizontalAlignment = .right
        alertButton.addTarget(self, action: #selector(onAlertTap), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc private func onAlertTap() {
        onTap?()
    }

    func bind(rate: String?, diff: Decimal?, alertMode: ChartPriceAlertMode, onTap: (() -> ())?) {
        self.onTap = onTap

        rateLabel.text = rate

        guard let diff = diff else {
            diffLabel.text = nil
            diffImageView.image = nil
            return
        }
        let color: UIColor = diff.isSignMinus ? .themeLucian : .themeRemus
        let imageName = diff.isSignMinus ? "Price Down" : "Price Up"

        diffImageView.image = UIImage(named: imageName)?.tinted(with: color)

        let formattedDiff = ChartCurrentRateView.formatter.string(from: abs(diff) as NSNumber)
        diffLabel.text = formattedDiff.map { "\($0)%" }

        switch alertMode {
        case .on:
            alertButton.setImage(UIImage(named: "Notification Small Icon")?.tinted(with: .themeJacob), for: .normal)
            updateNotificationControls(notificationsHidden: false)
        case .off:
            alertButton.setImage(UIImage(named: "Notification Small Icon")?.tinted(with: .themeGray), for: .normal)
            updateNotificationControls(notificationsHidden: false)
        case .hidden:
            alertButton.setImage(nil, for: .normal)
            updateNotificationControls(notificationsHidden: true)
        }
    }

    private func updateNotificationControls(notificationsHidden: Bool) {
        alertButton.isUserInteractionEnabled = !notificationsHidden
        diffLabel.snp.updateConstraints { maker in
            let inset = notificationsHidden ? CGFloat.margin4x : CGFloat.margin4x + CGFloat.margin2x + 16
            maker.trailing.equalToSuperview().inset(inset)
        }

}

}

extension ChartCurrentRateView {

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

}
