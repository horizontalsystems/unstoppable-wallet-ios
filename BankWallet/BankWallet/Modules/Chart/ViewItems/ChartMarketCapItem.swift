import ActionSheet

class ChartMarketCapItem: BaseActionItem {

    var setMarketCapTitle: ((String) -> ())?
    var setMarketCapText: ((String?) -> ())?
    var setLowTitle: ((String) -> ())?
    var setLowText: ((String?) -> ())?
    var setHighTitle: ((String) -> ())?
    var setHighText: ((String?) -> ())?

    init(tag: Int) {
        super.init(cellType: ChartMarketCapItemView.self, tag: tag, required: true)

        height = ChartRateTheme.currentRateHeight
    }

}
