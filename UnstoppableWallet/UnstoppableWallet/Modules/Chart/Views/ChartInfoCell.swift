import UIKit
import SnapKit

class ChartInfoCell: UITableViewCell {
    public static let cellHeight: CGFloat = 186

    private let separator = UIView()
    private let volumeView = CaptionValueView()
    private let marketCapView = CaptionValueView()
    private let circulationView = CaptionValueView()
    private let totalView = CaptionValueView()
    private let startDateView = CaptionValueView()
    private let websiteView = CaptionValueView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        separator.backgroundColor = .themeSteel20

        contentView.addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        contentView.addSubview(volumeView)
        volumeView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(separator.snp.bottom).offset(CGFloat.margin3x)
        }
        volumeView.set(caption: "chart.volume".localized)

        contentView.addSubview(marketCapView)
        marketCapView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(volumeView.snp.bottom)
        }
        marketCapView.set(caption: "chart.market_cap".localized)

        contentView.addSubview(circulationView)
        circulationView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(marketCapView.snp.bottom)
        }
        circulationView.set(caption: "chart.circulation".localized)

        contentView.addSubview(totalView)
        totalView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(circulationView.snp.bottom)
        }
        totalView.set(caption: "chart.max_supply".localized)

        contentView.addSubview(startDateView)
        startDateView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(totalView.snp.bottom)
        }
        startDateView.set(caption: "chart.start_date".localized)

        contentView.addSubview(websiteView)
        websiteView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(startDateView.snp.bottom)
            maker.bottom.equalToSuperview()
        }
        websiteView.set(caption: "chart.website".localized)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(marketCap: MarketInfoViewItem.Value, volume: MarketInfoViewItem.Value, supply: String?, maxSupply: MarketInfoViewItem.Value, startDate: MarketInfoViewItem.Value, website: MarketInfoViewItem.Value, onTapLink: (() -> ())?) {
        volumeView.set(value: volume.value, accent: volume.accent)
        marketCapView.set(value: marketCap.value, accent: marketCap.accent)
        circulationView.set(value: supply)
        totalView.set(value: maxSupply.value, accent: maxSupply.accent)
        startDateView.set(value: startDate.value, accent: startDate.accent)
        websiteView.set(value: website.value, accent: website.accent, link: true, onTap: onTapLink)
    }

}
