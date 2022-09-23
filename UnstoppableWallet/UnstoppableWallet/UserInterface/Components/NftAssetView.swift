import UIKit
import SnapKit
import ThemeKit
import Kingfisher

class NftAssetView: UIView {
    private static let imageMargin: CGFloat = .margin4
    private static let bottomHeight: CGFloat = 52

    private let button = UIButton()
    private let imageView = UIImageView()
    private let imagePlaceholderLabel = UILabel()
    private let nameLabel = UILabel()
    private let coinPriceLabel = UILabel()
    private let fiatPriceLabel = UILabel()

    private let onSaleWrapper = UIView()
    private let onSaleLabel = UILabel()

    private let countWrapper = UIView()
    private let countLabel = UILabel()

    var onTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.cornerRadius = .cornerRadius12
        button.layer.cornerCurve = .continuous
        button.setBackgroundColor(.themeLawrence, for: .normal)
        button.setBackgroundColor(.themeLawrencePressed, for: .highlighted)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)

        addSubview(imagePlaceholderLabel)
        addSubview(imageView)

        imagePlaceholderLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(imageView).inset(CGFloat.margin12)
            maker.centerY.equalTo(imageView)
        }

        imagePlaceholderLabel.numberOfLines = 0
        imagePlaceholderLabel.textAlignment = .center
        imagePlaceholderLabel.font = .microSB
        imagePlaceholderLabel.textColor = .themeGray

        imageView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview().inset(Self.imageMargin)
            maker.bottom.equalToSuperview().inset(Self.bottomHeight)
            maker.height.equalTo(imageView.snp.width)
        }

        imageView.contentMode = .scaleAspectFill
        imageView.cornerRadius = .cornerRadius8
        imageView.layer.cornerCurve = .continuous
        imageView.backgroundColor = .themeSteel10

        addSubview(onSaleWrapper)
        onSaleWrapper.snp.makeConstraints { maker in
            maker.top.trailing.equalTo(imageView).inset(CGFloat.margin4)
            maker.height.equalTo(15)
        }

        onSaleWrapper.backgroundColor = .themeLightGray
        onSaleWrapper.cornerRadius = .cornerRadius4
        onSaleWrapper.layer.cornerCurve = .continuous

        onSaleWrapper.addSubview(onSaleLabel)
        onSaleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4)
            maker.centerY.equalToSuperview()
        }

        onSaleLabel.font = .microSB
        onSaleLabel.textColor = .themeDarker
        onSaleLabel.text = "nft_collections.on_sale".localized

        addSubview(countWrapper)
        countWrapper.snp.makeConstraints { maker in
            maker.leading.top.equalTo(imageView).inset(CGFloat.margin4)
            maker.height.equalTo(15)
        }

        countWrapper.backgroundColor = .themeBlack50
        countWrapper.cornerRadius = .cornerRadius4
        countWrapper.layer.cornerCurve = .continuous

        let countImageView = UIImageView()

        countWrapper.addSubview(countImageView)
        countImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(12)
        }

        countImageView.image = UIImage(named: "nft_amount_12")?.withTintColor(.themeSteelLight)

        countWrapper.addSubview(countLabel)
        countLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(countImageView.snp.trailing).offset(2)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4)
            maker.centerY.equalToSuperview()
        }

        countLabel.font = .microSB
        countLabel.textColor = .themeSteelLight

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(10)
            maker.top.equalTo(imageView.snp.bottom).offset(CGFloat.margin12)
        }

        nameLabel.font = .microSB
        nameLabel.textColor = .themeGray

        addSubview(coinPriceLabel)
        coinPriceLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(10)
            maker.top.equalTo(nameLabel.snp.bottom).offset(CGFloat.margin4)
        }

        coinPriceLabel.setContentHuggingPriority(.required, for: .horizontal)
        coinPriceLabel.font = .captionSB
        coinPriceLabel.textColor = .themeLeah

        addSubview(fiatPriceLabel)
        fiatPriceLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(coinPriceLabel.snp.trailing).offset(CGFloat.margin4)
            maker.trailing.equalToSuperview().inset(10)
            maker.centerY.equalTo(coinPriceLabel)
        }

        fiatPriceLabel.font = .micro
        fiatPriceLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTap?()
    }

    var imagePlaceholder: String? {
        get { imagePlaceholderLabel.text }
        set { imagePlaceholderLabel.text = newValue }
    }

    var name: String? {
        get { nameLabel.text }
        set { nameLabel.text = newValue }
    }

    var coinPrice: String? {
        get { coinPriceLabel.text }
        set { coinPriceLabel.text = newValue }
    }

    var fiatPrice: String? {
        get { fiatPriceLabel.text }
        set { fiatPriceLabel.text = newValue }
    }

    var onSaleHidden: Bool {
        get { onSaleWrapper.isHidden }
        set { onSaleWrapper.isHidden = newValue }
    }

    var count: String? {
        get { countLabel.text }
        set {
            countLabel.text = newValue
            countWrapper.isHidden = newValue == nil
        }
    }

    func setImage(url: String?) {
        imagePlaceholderLabel.isHidden = false

        if let urlString = url, let url = URL(string: urlString) {
            imageView.kf.setImage(with: url, options: [.onlyLoadFirstFrame, .transition(.fade(0.5))]) { [weak self] result in
                if case .success = result {
                    self?.imagePlaceholderLabel.isHidden = true
                }
            }
        } else {
            imageView.image = nil
        }
    }

}

extension NftAssetView {

    static func height(containerWidth: CGFloat) -> CGFloat {
        let imageSize = containerWidth - imageMargin * 2
        return imageMargin + imageSize + bottomHeight
    }

}
