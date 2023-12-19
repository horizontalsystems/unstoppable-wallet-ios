import UIKit

class MarketCategoryView: UIView {
    static let height: CGFloat = 140

    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let stackView = UIStackView()
    private let marketCapLabel = UILabel()
    private let diffLabel = UILabel()

    private let button = UIButton()

    var onTap: (() -> Void)? {
        didSet {
            button.isUserInteractionEnabled = onTap != nil
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .themeLawrence
        cornerRadius = .cornerRadius12
        layer.cornerCurve = .continuous

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        button.isUserInteractionEnabled = false

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview()
        }

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        stackView.axis = .horizontal
        stackView.spacing = .margin6

        stackView.addArrangedSubview(marketCapLabel)
        marketCapLabel.font = .caption
        marketCapLabel.textColor = .themeGray

        stackView.addArrangedSubview(diffLabel)
        diffLabel.font = .caption

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.bottom.equalTo(stackView.snp.top).offset(-CGFloat.margin8)
        }

        nameLabel.numberOfLines = 0
        nameLabel.font = .subhead1
        nameLabel.textColor = .themeLeah

        updateUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateUI()
    }

    @objc private func didTapButton() {
        onTap?()
    }

    private func updateUI() {
        button.setBackgroundColor(color: .themeLawrencePressed, forState: .highlighted)
    }

    func set(viewItem: MarketOverviewCategoryViewModel.ViewItem) {
        imageView.setImage(withUrlString: viewItem.imageUrl, placeholder: nil)

        nameLabel.text = viewItem.name

        marketCapLabel.text = viewItem.marketCap
        diffLabel.text = viewItem.diff
        diffLabel.textColor = viewItem.diffType.textColor

        nameLabel.snp.updateConstraints { maker in
            maker.bottom.equalTo(stackView.snp.top).offset(viewItem.marketCap == nil ? 0 : -CGFloat.margin8)
        }
    }
}
