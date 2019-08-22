import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class ChartMarketCapItemView: BaseActionItemView {
    private let marketCapText = UILabel()
    private let marketCapTitle = UILabel()
    private let highText = UILabel()
    private let highTitle = UILabel()
    private let lowText = UILabel()
    private let lowTitle = UILabel()

    override var item: ChartMarketCapItem? { return _item as? ChartMarketCapItem }

    override func initView() {
        super.initView()

        addSubview(marketCapText)
        marketCapText.font = ChartRateTheme.marketCapTextFont
        marketCapText.textColor = ChartRateTheme.marketCapTextColor

        marketCapText.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(ChartRateTheme.margin)
            maker.top.equalToSuperview()
        }
        addSubview(highText)
        highText.font = ChartRateTheme.marketCapTextFont
        highText.textColor = ChartRateTheme.marketCapTextColor
        highText.snp.makeConstraints { maker in
            maker.left.equalTo(marketCapText.snp.right).offset(ChartRateTheme.margin)
            maker.width.equalTo(marketCapText.snp.width)
            maker.top.equalToSuperview()
        }
        addSubview(lowText)
        lowText.font = ChartRateTheme.marketCapTextFont
        lowText.textColor = ChartRateTheme.marketCapTextColor

        lowText.snp.makeConstraints { maker in
            maker.left.equalTo(highText.snp.right).offset(ChartRateTheme.margin)
            maker.right.equalToSuperview().offset(-ChartRateTheme.margin)
            maker.width.equalTo(marketCapText.snp.width)
            maker.top.equalToSuperview()
        }

        addSubview(marketCapTitle)
        marketCapTitle.font = ChartRateTheme.marketCapTitleFont
        marketCapTitle.textColor = ChartRateTheme.marketCapTitleColor
        marketCapTitle.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(ChartRateTheme.margin)
            maker.top.equalToSuperview().offset(ChartRateTheme.marketCapTitleTopMargin)
        }
        addSubview(highTitle)
        highTitle.font = ChartRateTheme.marketCapTitleFont
        highTitle.textColor = ChartRateTheme.marketCapTitleColor
        highTitle.snp.makeConstraints { maker in
            maker.left.equalTo(marketCapTitle.snp.right).offset(ChartRateTheme.margin)
            maker.width.equalTo(marketCapTitle.snp.width)
            maker.top.equalToSuperview().offset(ChartRateTheme.marketCapTitleTopMargin)
        }
        addSubview(lowTitle)
        lowTitle.font = ChartRateTheme.marketCapTitleFont
        lowTitle.textColor = ChartRateTheme.marketCapTitleColor
        lowTitle.snp.makeConstraints { maker in
            maker.left.equalTo(highTitle.snp.right).offset(ChartRateTheme.margin)
            maker.right.equalToSuperview().offset(-ChartRateTheme.margin)
            maker.width.equalTo(marketCapTitle.snp.width)
            maker.top.equalToSuperview().offset(ChartRateTheme.marketCapTitleTopMargin)
        }

        item?.setMarketCapTitle = { [weak self] text in
            self?.marketCapTitle.text = text
        }
        item?.setMarketCapText = { [weak self] text in
            self?.marketCapText.text = text
        }
        item?.setLowTitle = { [weak self] text in
            self?.lowTitle.text = text
        }
        item?.setLowText = { [weak self] text in
            self?.lowText.text = text
        }
        item?.setHighTitle = { [weak self] text in
            self?.highTitle.text = text
        }
        item?.setHighText = { [weak self] text in
            self?.highText.text = text
        }
    }

}
