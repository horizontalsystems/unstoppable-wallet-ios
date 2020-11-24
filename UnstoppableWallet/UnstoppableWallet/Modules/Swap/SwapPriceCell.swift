import ThemeKit
import RxSwift
import HUD

class SwapPriceCell: UITableViewCell {
    let cellHeight: CGFloat = 24

    private static let spinnerRadius: CGFloat = 8
    private static let spinnerLineWidth: CGFloat = 2

    private let loadingSpinner = HUDProgressView(
            strokeLineWidth: SwapPriceCell.spinnerLineWidth,
            radius: SwapPriceCell.spinnerRadius,
            strokeColor: .themeOz
    )
    private let priceLabel = UILabel()
    private let switchButton = UIButton()

    var onSwitch: (() -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(loadingSpinner)
        loadingSpinner.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
            maker.width.height.equalTo(SwapPriceCell.spinnerRadius * 2 + SwapPriceCell.spinnerLineWidth)
        }

        loadingSpinner.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        loadingSpinner.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        loadingSpinner.isHidden = false

        contentView.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(loadingSpinner)
            maker.leading.equalTo(loadingSpinner.snp.trailing).offset(CGFloat.margin2x)
        }

        priceLabel.font = .subhead2
        priceLabel.textAlignment = .center

        contentView.addSubview(switchButton)
        switchButton.snp.makeConstraints { maker in
            maker.leading.equalTo(priceLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.bottom.equalToSuperview()
        }

        switchButton.setImage(UIImage(named: "Swap Switch Icon")?.tinted(with: .themeGray), for: .normal)
        switchButton.addTarget(self, action: #selector(onTapSwitch), for: .touchUpInside)
        switchButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        switchButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        switchButton.isHidden = true // temporarily hide Switch button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSwitch() {
        onSwitch?()
    }

    func set(loading: Bool) {
        loadingSpinner.isHidden = !loading
        if loading {
            loadingSpinner.startAnimating()
        } else {
            loadingSpinner.stopAnimating()
        }
    }

    func set(price: String?) {
        if let price = price {
            priceLabel.textColor = .themeGray
            priceLabel.text = price
        } else {
            priceLabel.textColor = .themeGray50
            priceLabel.text = "swap.price".localized
        }
    }

}
