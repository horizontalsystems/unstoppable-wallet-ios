import ThemeKit
import RxSwift
import HUD

class SwapPriceCell: UITableViewCell {
    let cellHeight: CGFloat = 24

    private let spinner = HUDActivityView.create(with: .medium24)
    private let priceLabel = UILabel()
    private let switchButton = UIButton()

    var onSwitch: (() -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        spinner.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        spinner.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        spinner.isHidden = false

        contentView.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(spinner)
            maker.leading.equalTo(spinner.snp.trailing).offset(CGFloat.margin2x)
        }

        priceLabel.font = .subhead2
        priceLabel.textAlignment = .center

        contentView.addSubview(switchButton)
        switchButton.snp.makeConstraints { maker in
            maker.leading.equalTo(priceLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.bottom.equalToSuperview()
        }

        switchButton.setImage(UIImage(named: "arrow_medium_2_swap_24")?.tinted(with: .themeGray), for: .normal)
        switchButton.addTarget(self, action: #selector(onTapSwitch), for: .touchUpInside)
        switchButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        switchButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSwitch() {
        onSwitch?()
    }

    func set(loading: Bool) {
        spinner.isHidden = !loading
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    func set(price: String?) {
        if let price = price {
            priceLabel.textColor = .themeGray
            priceLabel.text = price
        } else {
            priceLabel.textColor = .themeGray50
            priceLabel.text = "price".localized
        }
    }

}
