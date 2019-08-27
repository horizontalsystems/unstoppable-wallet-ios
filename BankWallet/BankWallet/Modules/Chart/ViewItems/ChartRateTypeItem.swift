import ActionSheet

class ChartRateTypeItem: BaseActionItem {

    var bindButton: ((String, Int, (() -> ())?) -> ())?
    var setSelected: ((Int) -> ())?
    var setEnabled: ((Int) -> ())?
    var showPoint: ((String?, String?) -> ())?

    init(tag: Int) {

        super.init(cellType: ChartRateTypeItemView.self, tag: tag, required: true)

        showSeparator = false
        height = ChartRateTheme.chartRateTypeHeight
    }

}
