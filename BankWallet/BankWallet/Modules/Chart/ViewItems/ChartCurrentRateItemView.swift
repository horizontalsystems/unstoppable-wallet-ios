import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class ChartCurrentRateItemView: BaseActionItemView {
    private let currentRateLabel = UILabel()
    private let rateDiffView = RateDiffView()

    override var item: ChartCurrentRateItem? {
        _item as? ChartCurrentRateItem
    }

    override func initView() {
        super.initView()

        addSubview(currentRateLabel)
        currentRateLabel.font = .headline2
        currentRateLabel.textColor = .themeOz
        currentRateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        currentRateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        rateDiffView.font = .subhead1

        addSubview(rateDiffView)
        rateDiffView.snp.makeConstraints { maker in
            maker.leading.equalTo(currentRateLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.centerY.equalTo(currentRateLabel.snp.centerY)
        }

        item?.bindRate = { [weak self] rate in
            self?.currentRateLabel.text = rate
        }

        item?.bindDiff = { [weak self] diff in
            self?.rateDiffView.set(value: diff)
        }

    }

}
