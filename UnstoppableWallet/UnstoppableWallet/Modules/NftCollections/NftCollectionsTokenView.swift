import UIKit
import SnapKit
import ThemeKit

class NftCollectionsTokenView: UIView {
    private static let imageMargin: CGFloat = .margin4
    private static let bottomHeight: CGFloat = 52

    private let button = UIButton()
    private let imageView = NftImageView()
    private let nameLabel = UILabel()
    private let coinPriceLabel = UILabel()
    private let fiatPriceLabel = UILabel()
    private let onSaleWrapper = UIView()
    private let onSaleLabel = UILabel()

    var onTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.cornerRadius = .cornerRadius12
        button.setBackgroundColor(.themeLawrence, for: .normal)
        button.setBackgroundColor(.themeLawrencePressed, for: .highlighted)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview().inset(Self.imageMargin)
            maker.bottom.equalToSuperview().inset(Self.bottomHeight)
            maker.height.equalTo(imageView.snp.width)
        }

        imageView.cornerRadius = .cornerRadius8

        addSubview(onSaleWrapper)
        onSaleWrapper.snp.makeConstraints { maker in
            maker.top.trailing.equalTo(imageView).inset(CGFloat.margin4)
            maker.height.equalTo(15)
        }

        onSaleWrapper.backgroundColor = .themeLightGray
        onSaleWrapper.cornerRadius = .cornerRadius4

        onSaleWrapper.addSubview(onSaleLabel)
        onSaleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4)
            maker.centerY.equalToSuperview()
        }

        onSaleLabel.font = .microSB
        onSaleLabel.textColor = .themeDarker
        onSaleLabel.text = "nft_collections.on_sale".localized

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

    func setImage(url: String?) {
        imageView.setImage(url: url)
    }

    var imageRatio: CGFloat {
        imageView.imageRatio
    }

}

extension NftCollectionsTokenView {

    static func height(containerWidth: CGFloat) -> CGFloat {
        let imageSize = containerWidth - imageMargin * 2
        return imageMargin + imageSize + bottomHeight
    }

}
