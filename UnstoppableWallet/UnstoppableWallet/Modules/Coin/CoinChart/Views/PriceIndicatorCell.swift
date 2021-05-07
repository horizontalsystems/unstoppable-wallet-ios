import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class PriceIndicatorCell: BaseThemeCell {
    static let cellHeight: CGFloat = 67

    private let lowPriceLabel = UILabel()
    private let highPriceLabel = UILabel()
    private let rangeLabel = UILabel()
    private let priceIndicator = UIImageView(image: UIImage(named: "slider_indicator"))
    private let sliderPointerSpacer = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        topSeparatorView.snp.remakeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview()
            maker.height.equalTo(0)
        }

        let sliderViewHolder = UIView()
        wrapperView.addSubview(sliderViewHolder)
        sliderViewHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview().inset(CGFloat.margin12)
        }

        sliderViewHolder.addSubview(priceIndicator)
        priceIndicator.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
        }

        sliderViewHolder.addSubview(sliderPointerSpacer)
        sliderPointerSpacer.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
            maker.bottom.equalTo(priceIndicator.snp.top)
            maker.width.equalTo(priceIndicator.snp.width).multipliedBy(0)
        }

        let sliderPointer = UIImageView(image: UIImage(named: "slider_pointer"))
        sliderViewHolder.addSubview(sliderPointer)
        sliderPointer.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.bottom.equalTo(priceIndicator.snp.top).offset(-CGFloat.margin4)
            maker.leading.equalTo(sliderPointerSpacer.snp.trailing).offset(-sliderPointer.frame.size.width / 2)
        }

        wrapperView.addSubview(lowPriceLabel)
        lowPriceLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        lowPriceLabel.font = .caption
        lowPriceLabel.textColor = .themeBran

        wrapperView.addSubview(highPriceLabel)
        highPriceLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        highPriceLabel.font = .caption
        highPriceLabel.textColor = .themeBran

        wrapperView.addSubview(rangeLabel)
        rangeLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        rangeLabel.font = .caption
        rangeLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func bind(viewItem: PriceIndicatorViewItem) {
        lowPriceLabel.text = viewItem.low
        highPriceLabel.text = viewItem.high
        rangeLabel.text = viewItem.range.description

        sliderPointerSpacer.snp.remakeConstraints { maker in
            maker.leading.top.equalToSuperview()
            maker.bottom.equalTo(priceIndicator.snp.top)
            maker.width.equalTo(priceIndicator.snp.width).multipliedBy(viewItem.currentPercentage)
        }
    }

}
