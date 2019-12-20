import ActionSheet

class ChartMarketCapItem: BaseActionItem {
    var setVolume: ((String?) -> ())?
    var setMarketCap: ((String?) -> ())?
    var setCirculation: ((String?) -> ())?
    var setTotal: ((String?) -> ())?

    init(tag: Int) {
        super.init(cellType: ChartMarketCapItemView.self, tag: tag, required: true)

        height = 143
    }

}
