import GrouviActionSheet

class SendAddressItem: BaseActionItem {

    var onScanClicked: (() -> ())?
    var onPasteClicked: (() -> ())?
    var onDeleteClicked: (() -> ())?

    var bindAddress: ((String?, String?) -> ())? // (address, error)

    init(tag: Int) {
        super.init(cellType: SendAddressItemView.self, tag: tag, required: true)

        showSeparator = false
        height = SendTheme.addressHeight
    }

}
