import UIKit
import ActionSheet
import SnapKit

class ChartMarketCapItemView: BaseActionItemView {
    private let separator = UIView()
    private let volumeView = CaptionValueView()
    private let marketCapView = CaptionValueView()
    private let circulationView = CaptionValueView()
    private let totalView = CaptionValueView()
    private let sourceView = CaptionValueView()

    override var item: ChartMarketCapItem? {
        _item as? ChartMarketCapItem
    }

    override func initView() {
        super.initView()

        separator.backgroundColor = .appSteel20

        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        volumeView.set(caption: "chart.volume".localized)

        addSubview(volumeView)
        volumeView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(separator.snp.bottom).offset(CGFloat.margin2x)
        }

        marketCapView.set(caption: "chart.market_cap".localized)

        addSubview(marketCapView)
        marketCapView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(volumeView.snp.bottom).offset(CGFloat.margin2x)
        }

        circulationView.set(caption: "chart.circulation".localized)

        addSubview(circulationView)
        circulationView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(marketCapView.snp.bottom).offset(CGFloat.margin2x)
        }

        totalView.set(caption: "chart.max_supply".localized)

        addSubview(totalView)
        totalView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(circulationView.snp.bottom).offset(CGFloat.margin2x)
        }

        sourceView.set(value: "@CryptoCompare.com", font: .appCaption)

        addSubview(sourceView)
        sourceView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(totalView.snp.bottom).offset(CGFloat.margin2x)
        }

        item?.setVolume = { [weak self] value in
            self?.volumeView.set(value: value, accent: true)
        }

        item?.setMarketCap = { [weak self] value in
            self?.marketCapView.set(value: value, accent: true)
        }

        item?.setCirculation = { [weak self] value in
            self?.circulationView.set(value: value, accent: true)
        }

        item?.setTotal = { [weak self] value in
            self?.totalView.set(value: value, accent: true)
        }
    }

}
