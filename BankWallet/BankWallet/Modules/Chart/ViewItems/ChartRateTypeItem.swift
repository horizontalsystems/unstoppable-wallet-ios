import ActionSheet
import Chart

class ChartRateTypeItem: BaseActionItem {

    var setTitles: (([String]) -> ())?
    var setSelected: ((Int) -> ())?
    var showPoint: ((String?, String?, String?, String?) -> ())?         // Date, Time, Price, Volume

    var didSelect: ((Int) -> ())?

    init(tag: Int) {

        super.init(cellType: ChartRateTypeItemView.self, tag: tag, required: true)

        showSeparator = false
        height = .heightSingleLineCell
    }

}
