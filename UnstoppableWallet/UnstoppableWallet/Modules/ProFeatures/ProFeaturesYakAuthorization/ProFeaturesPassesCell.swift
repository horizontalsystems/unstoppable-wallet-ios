import UIKit
import ThemeKit
import ComponentKit
import RxSwift
import SnapKit

class ProFeaturesPassesCell: BaseThemeCell {
    static let height: CGFloat = 94
    private let disposeBag = DisposeBag()

    private let viewModel: ProFeaturesYakAuthorizationViewModel
    weak var parentViewController: UIViewController?

    private let backgroundImageView = UIImageView()
    private let button = UIButton()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private weak var proFeaturesActivateViewController: ProFeaturesActivateViewController?

    init(viewModel: ProFeaturesYakAuthorizationViewModel) {
        self.viewModel = viewModel
        super.init(style: .default, reuseIdentifier: nil)

        set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

        wrapperView.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        backgroundImageView.image = UIImage(named: "mask_group")

        wrapperView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)

        button.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
        }

        titleLabel.textColor = .themeBlack
        titleLabel.font = .headline2
        titleLabel.text = viewModel.title

        button.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin12)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
        }

        subtitleLabel.textColor = .themeBlack
        subtitleLabel.font = .caption
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = viewModel.subtitle

        subscribe(disposeBag, viewModel.showHudSignal) { show in
            if show {
                HudHelper.instance.showSpinner()
            } else {
                HudHelper.instance.hide()
            }
        }
        subscribe(disposeBag, viewModel.showLockInfoSignal) { [weak self] in self?.showLockInfo() }
        subscribe(disposeBag, viewModel.showSignMessageSignal) { [weak self] in self?.showSignMessage() }
        subscribe(disposeBag, viewModel.showErrorSignal) { HudHelper.instance.show(banner: .error(string: $0)) }
        subscribe(disposeBag, viewModel.showSuccessSignedSignal) { [weak self] in self?.showSuccessSigned() }
    }

    override init(style: CellStyle, reuseIdentifier: String?) {
        fatalError("init(coder:) has not been implemented")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        showLockInfo()
        //viewModel.authorize()
    }

    private func showLockInfo() {
        let viewController = ProFeatures.mountainYakBottomSheet {
            print("Can open main mint controller!")
        }

        parentViewController?.present(viewController, animated: true)
    }

    private func showSignMessage() {
        let viewController = ProFeaturesActivateViewController(
                config: .mountainYak,
                onSuccess: { [weak self] in self?.viewModel.activate() },
                onCancel: {  [weak self] in self?.viewModel.dismissSign() }
        )
        proFeaturesActivateViewController = viewController
        let navigationViewController = ThemeNavigationController(rootViewController: viewController)

        parentViewController?.present(navigationViewController, animated: true)
    }

    private func showSuccessSigned() {
        HudHelper.instance.show(banner: .done)
        proFeaturesActivateViewController?.dismiss(animated: true)
    }

}
