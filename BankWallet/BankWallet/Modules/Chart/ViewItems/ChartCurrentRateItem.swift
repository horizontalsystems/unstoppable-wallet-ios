import ActionSheet

class ChartCurrentRateItem: BaseActionItem {

    var bindRate: ((_ rate: String?) -> ())?
    var bindDiff: ((_ diff: String?, _ positive: Bool) -> ())?

    init(tag: Int) {
        super.init(cellType: ChartCurrentRateItemView.self, tag: tag, required: true)

        height = ChartRateTheme.currentRateHeight
    }

}
