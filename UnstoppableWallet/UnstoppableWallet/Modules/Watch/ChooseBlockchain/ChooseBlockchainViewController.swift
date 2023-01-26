import Foundation
import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit
import UIExtensions

class ChooseBlockchainViewController: CoinToggleViewController {
    private let viewModel: ChooseBlockchainViewModel
    private let gradientWrapperView = GradientView(gradientHeight: .margin16, fromColor: UIColor.themeTyler.withAlphaComponent(0), toColor: UIColor.themeTyler)
    private let watchButton = PrimaryButton()

    private weak var sourceViewController: UIViewController?

    init(viewModel: ChooseBlockchainViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        self.sourceViewController = sourceViewController

        super.init(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.searchController = nil

        title = "watch_address.choose_blockchain".localized

        view.addSubview(gradientWrapperView)
        gradientWrapperView.snp.makeConstraints { maker in
            maker.height.equalTo(.heightButton + .margin32 + .margin16).priority(.high)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        gradientWrapperView.addSubview(watchButton)
        watchButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        watchButton.set(style: .yellow)
        watchButton.setTitle("watch_address.watch".localized, for: .normal)
        watchButton.addTarget(self, action: #selector(onTapWatch), for: .touchUpInside)

        subscribe(disposeBag, viewModel.watchEnabledDriver) { [weak self] enabled in
            self?.watchButton.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.watchSignal) { [weak self] in
            HudHelper.instance.show(banner: .walletAdded)
            (self?.sourceViewController ?? self)?.dismiss(animated: true)
        }
        subscribe(disposeBag, viewModel.watchEnabledDriver) { [weak self] enabled in
            self?.watchButton.isEnabled = enabled
        }
    }

    @objc private func onTapWatch() {
        viewModel.onTapWatch()
    }

}
