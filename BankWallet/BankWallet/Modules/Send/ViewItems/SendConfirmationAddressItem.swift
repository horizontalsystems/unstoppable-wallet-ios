import GrouviActionSheet

class SendConfirmationAddressItem: BaseActionItem {

    let address: String
    var onHashTap: (() -> ())?

    init(address: String, tag: Int) {
        self.address = address

        super.init(cellType: SendConfirmationAddressItemView.self, tag: tag, required: true)

        height = SendTheme.confirmationAddressHeight
        showSeparator = false
    }

}
