import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class SendAddressItemView: BaseActionItemView {
    let addressInputField = AddressInputField(frame: .zero)

    override var item: SendAddressItem? { return _item as? SendAddressItem }

    override func initView() {
        super.initView()
        backgroundColor = .clear

        addSubview(addressInputField)
        addressInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.holderTopMargin)
            maker.bottom.equalToSuperview()
        }
        addressInputField.onScan = item?.onScanClicked
        addressInputField.onPaste = item?.onPasteClicked
        addressInputField.onDelete = item?.onDeleteClicked

        item?.bindAddress = { [weak self] address, error in
            self?.bind(address: address, error: error)
        }

        bind(address: nil, error: nil)
    }

    private func bind(address: String?, error: String?) {
        addressInputField.bind(address: address, error: error)
    }

}
