import UIKit
import SnapKit

class NoPasscodeViewController: WalletViewController {
    private let delegate: INoPasscodeViewDelegate

    private let infoLabel = UILabel()

    init(delegate: INoPasscodeViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(infoLabel)

        infoLabel.textColor = NoPasscodeTheme.infoLabelTextColor
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = NoPasscodeTheme.infoLabelFont
        infoLabel.text = "no_passcode.info_text".localized

        infoLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(NoPasscodeTheme.infoLabelHorizontalMargin)
            make.trailing.equalToSuperview().offset(-NoPasscodeTheme.infoLabelHorizontalMargin)
            make.centerY.equalToSuperview()
        }
    }

}

extension NoPasscodeViewController: INoPasscodeView {
}
