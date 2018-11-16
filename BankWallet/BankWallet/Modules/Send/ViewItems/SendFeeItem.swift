import GrouviActionSheet

class SendFeeItem: BaseActionItem {

    var bindFee: ((String?) -> ())?
    var bindConvertedFee: ((String?) -> ())?

    init(tag: Int) {
        super.init(cellType: SendFeeItemView.self, tag: tag, required: true)

        showSeparator = false
        height = SendTheme.feeHeight
    }

}
