import UIKit
import SnapKit

class NoPasscodeViewController: WalletViewController {
    private let delegate: INoPasscodeViewDelegate

    private let wrapperView = UIView()
    private let iconImageView = UIImageView()
    private let infoLabel = UILabel()

    init(delegate: INoPasscodeViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(wrapperView)
        wrapperView.addSubview(iconImageView)
        wrapperView.addSubview(infoLabel)

        wrapperView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        iconImageView.contentMode = .center
        iconImageView.image = UIImage(named: "No Passcode Icon")?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = NoPasscodeTheme.iconColor

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(NoPasscodeTheme.iconSize)
        }

        infoLabel.textColor = NoPasscodeTheme.infoLabelTextColor
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = NoPasscodeTheme.infoLabelFont
        infoLabel.text = "no_passcode.info_text".localized

        infoLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(NoPasscodeTheme.infoLabelHorizontalMargin)
            make.trailing.equalToSuperview().offset(-NoPasscodeTheme.infoLabelHorizontalMargin)
            make.top.equalTo(self.iconImageView.snp.bottom).offset(NoPasscodeTheme.iconBottomMargin)
            make.bottom.equalToSuperview()
        }
    }

}

extension NoPasscodeViewController: INoPasscodeView {
}
