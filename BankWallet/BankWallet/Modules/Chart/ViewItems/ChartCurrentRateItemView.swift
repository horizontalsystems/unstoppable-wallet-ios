import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class ChartCurrentRateItemView: BaseActionItemView {
    private let currentRateLabel = UILabel()
    private let diffLabel = UILabel()

    override var item: ChartCurrentRateItem? { return _item as? ChartCurrentRateItem }

    override func initView() {
        super.initView()

        addSubview(currentRateLabel)
        currentRateLabel.font = ChartRateTheme.currentRateFont
        currentRateLabel.textColor = ChartRateTheme.currentRateColor
        currentRateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        currentRateLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(ChartRateTheme.smallMargin)
            maker.leading.equalToSuperview().offset(ChartRateTheme.margin)
        }

        addSubview(diffLabel)
        diffLabel.font = ChartRateTheme.diffRateFont
        diffLabel.textColor = ChartRateTheme.diffRatePositiveColor

        diffLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(ChartRateTheme.margin)
            maker.leading.equalTo(self.currentRateLabel.snp.trailing).offset(ChartRateTheme.mediumMargin)
            maker.trailing.equalToSuperview().offset(-ChartRateTheme.margin)
        }

        item?.bindRate = { [weak self] rate in
            self?.currentRateLabel.text = rate
        }

        item?.bindDiff = { [weak self] diff, positive in
            guard let diff = diff else {
                self?.diffLabel.text = nil
                return
            }
            self?.diffLabel.textColor = positive ? ChartRateTheme.diffRatePositiveColor : ChartRateTheme.diffRateNegativeColor
            self?.diffLabel.text = diff
        }

    }

}
