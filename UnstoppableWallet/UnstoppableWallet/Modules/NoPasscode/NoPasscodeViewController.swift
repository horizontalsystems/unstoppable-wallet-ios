import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class NoPasscodeViewController: ThemeViewController {
    enum Mode {
        case noPasscode
        case cannotCheckPasscode
        case jailbreak
    }

    private let mode: Mode

    private let containerView = UIView()
    private let wrapperView = UIView()
    private let iconImageView = UIImageView()
    private let infoLabel = UILabel()

    private let completion: (() -> Void)?

    init(mode: Mode, completion: (() -> Void)? = nil) {
        self.mode = mode
        self.completion = completion

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(containerView)
        containerView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        containerView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        wrapperView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        iconImageView.contentMode = .center
        iconImageView.image = UIImage(named: "attention_48")?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = .themeGray

        wrapperView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(42)
            make.top.equalTo(iconImageView.snp.bottom).offset(CGFloat.margin8x)
            make.bottom.equalToSuperview()
        }

        infoLabel.textColor = .themeGray
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = .body

        switch mode {
        case .jailbreak:
            infoLabel.text = "jailbreak.info_text".localized

            let understandButton = PrimaryButton()
            view.addSubview(understandButton)
            understandButton.snp.makeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
                maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin32)
                maker.top.equalTo(containerView.snp.bottom).offset(CGFloat.margin32)
            }

            understandButton.set(style: .yellow)
            understandButton.setTitle("button.i_understand".localized, for: .normal)
            understandButton.addTarget(self, action: #selector(onUnderstand), for: .touchUpInside)
        case .noPasscode:
            infoLabel.text = "no_passcode.info_text".localized

            containerView.snp.makeConstraints { maker in
                maker.bottom.equalToSuperview()
            }
        case .cannotCheckPasscode:
            infoLabel.text = "cannot_check_passcode.info_text".localized

            containerView.snp.makeConstraints { maker in
                maker.bottom.equalToSuperview()
            }
        }
    }

    @objc private func onUnderstand() {
        dismiss(animated: true, completion: completion)
    }
}
