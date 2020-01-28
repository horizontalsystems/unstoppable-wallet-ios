import UIKit
import SnapKit
import ThemeKit

class NoPasscodeViewController: ThemeViewController {
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

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(72)
        }

        iconImageView.contentMode = .center
        iconImageView.image = UIImage(named: "No Passcode Icon")?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = .themeGray

        infoLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(42)
            make.top.equalTo(self.iconImageView.snp.bottom).offset(CGFloat.margin8x)
            make.bottom.equalToSuperview()
        }

        infoLabel.textColor = .themeGray
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = .body
        infoLabel.text = "no_passcode.info_text".localized
    }

}

extension NoPasscodeViewController: INoPasscodeView {
}
