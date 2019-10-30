import ActionSheet

class ChartCurrentRateItem: BaseActionItem {

    var bindRate: ((_ rate: String?) -> ())?
    var bindDiff: ((Decimal?) -> ())?

    init(tag: Int) {
        super.init(cellType: ChartCurrentRateItemView.self, tag: tag, required: true)

        height = .heightSingleLineCell
    }

}
