import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendTitleItemView: BaseActionItemView {

    var titleLabel = UILabel()
    var scanQRButton = RespondView()

    override var item: SendTitleItem? { return _item as? SendTitleItem }

    override func initView() {
        super.initView()

        titleLabel.font = SendTheme.sendTitleFont
        titleLabel.textColor = UIColor.cryptoDark
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().offset(-SendTheme.titleBottomMargin)
        }

        let qrImageView = TintImageView(image: UIImage(named: "Scan QR Icon"), tintColor: .black, selectedTintColor: .gray)
        scanQRButton.delegate = qrImageView
        scanQRButton.handleTouch = item?.onQRScan
        addSubview(scanQRButton)
        scanQRButton.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(SendTheme.scanQRWidth)
        }
        scanQRButton.addSubview(qrImageView)
        qrImageView.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview()
            maker.size.equalTo(CGSize(width: SendTheme.qrSideSize, height: SendTheme.qrSideSize))
        }
    }

    override func updateView() {
        super.updateView()
        if let item = item {
            titleLabel.text = item.title
        }
    }

}
