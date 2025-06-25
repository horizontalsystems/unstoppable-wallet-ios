
import Foundation
import RxCocoa
import RxSwift
import SectionsTableView

import UIExtensions
import UIKit

class ChooseWatchViewController: CoinToggleViewController {
    private let viewModel: ChooseWatchViewModel
    private let gradientWrapperView = BottomGradientHolder()
    private let watchButton = PrimaryButton()

    private let onWatch: () -> Void

    init(viewModel: ChooseWatchViewModel, onWatch: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onWatch = onWatch

        super.init(viewModel: viewModel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
            self?.onWatch()
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
