import UIKit
import SnapKit

class ChartInfoView: UIView {
    private let separator = UIView()
    private let volumeView = CaptionValueView()
    private let marketCapView = CaptionValueView()
    private let circulationView = CaptionValueView()
    private let totalView = CaptionValueView()

    init() {
        super.init(frame: .zero)

        separator.backgroundColor = .themeSteel20

        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        addSubview(volumeView)
        volumeView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(separator.snp.bottom).offset(CGFloat.margin2x)
        }
        volumeView.set(caption: "chart.volume".localized)

        addSubview(marketCapView)
        marketCapView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(volumeView.snp.bottom).offset(CGFloat.margin2x)
        }
        marketCapView.set(caption: "chart.market_cap".localized)

        addSubview(circulationView)
        circulationView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(marketCapView.snp.bottom).offset(CGFloat.margin2x)
        }
        circulationView.set(caption: "chart.circulation".localized)

        addSubview(totalView)
        totalView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(circulationView.snp.bottom).offset(CGFloat.margin2x)
        }
        totalView.set(caption: "chart.max_supply".localized)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(marketCap: MarketInfoViewItem.Value, volume: MarketInfoViewItem.Value, supply: String?, maxSupply: String?) {
        volumeView.set(value: volume.value, accent: volume.accent)
        marketCapView.set(value: marketCap.value, accent: marketCap.accent)
        circulationView.set(value: supply)
        totalView.set(value: maxSupply)
    }

}
