import Foundation
import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit
import UIExtensions

class ChooseWatchViewController: CoinToggleViewController {
    private let viewModel: ChooseWatchViewModel
    private let gradientWrapperView = BottomGradientHolder()
    private let watchButton = PrimaryButton()

    private weak var sourceViewController: UIViewController?

    init(viewModel: ChooseWatchViewModel, sourceViewController: UIViewController?) {
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

        title = viewModel.title

        // remake to bind with bottom view
        tableView.snp.remakeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        gradientWrapperView.add(to: self, under: tableView)
        gradientWrapperView.addSubview(watchButton)

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setInitialState(bottomPadding: gradientWrapperView.height)
    }

    @objc private func onTapWatch() {
        viewModel.onTapWatch()
    }

}
