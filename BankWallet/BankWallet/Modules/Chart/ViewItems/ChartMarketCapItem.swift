import ActionSheet

class ChartMarketCapItem: BaseActionItem {
    var setTypeTitle: ((String) -> ())?
    var setLow: ((String?) -> ())?
    var setHigh: ((String?) -> ())?
    var setVolume: ((String?) -> ())?
    var setMarketCap: ((String?) -> ())?
    var setCirculation: ((String?) -> ())?
    var setTotal: ((String?) -> ())?

    init(tag: Int) {
        super.init(cellType: ChartMarketCapItemView.self, tag: tag, required: true)

        height = 170
    }

}
