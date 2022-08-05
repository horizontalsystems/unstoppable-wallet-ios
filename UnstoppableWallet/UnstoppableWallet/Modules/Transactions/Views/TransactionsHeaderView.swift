import UIKit
import SnapKit
import RxSwift
import UIExtensions
import ThemeKit
import ComponentKit

class TransactionsHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let viewModel: TransactionsViewModel
    private let disposeBag = DisposeBag()
    weak var viewController: UIViewController?

    private let blockchainButton = SecondaryButton()
    private let tokenButton = SecondaryButton()

    init(viewModel: TransactionsViewModel) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        contentView.addSubview(blockchainButton)
        blockchainButton.snp.makeConstraints { maker in
            maker.leading.centerY.equalToSuperview()
        }

        blockchainButton.set(style: .transparent)
        blockchainButton.set(image: UIImage(named: "arrow_small_down_20"))
        blockchainButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        blockchainButton.addTarget(self, action: #selector(onTapBlockchainButton), for: .touchUpInside)

        contentView.addSubview(tokenButton)
        tokenButton.snp.makeConstraints { maker in
            maker.trailing.centerY.equalToSuperview()
        }

        tokenButton.set(style: .transparent)
        tokenButton.set(image: UIImage(named: "arrow_small_down_20"))
        tokenButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tokenButton.addTarget(self, action: #selector(onTapTokenButton), for: .touchUpInside)

        let separatorView = UIView()

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        subscribe(disposeBag, viewModel.blockchainTitleDriver) { [weak self] title in
            self?.blockchainButton.setTitle(title, for: .normal)
        }
        subscribe(disposeBag, viewModel.tokenTitleDriver) { [weak self] title in
            self?.tokenButton.setTitle(title, for: .normal)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapBlockchainButton() {
        let viewItems = viewModel.blockchainViewItems

        let alertController = AlertRouter.module(
                title: "transactions.blockchain".localized,
                viewItems: viewItems.enumerated().map { (index, viewItem) in
                    AlertViewItem(text: viewItem.title, selected: viewItem.selected)
                }
        ) { [weak self] index in
            self?.viewModel.onSelectBlockchain(uid: viewItems[index].uid)
        }

        viewController?.present(alertController, animated: true)
    }

    @objc private func onTapTokenButton() {
        let module = TransactionsCoinSelectModule.viewController(configuredToken: viewModel.configuredToken, delegate: self)
        viewController?.present(module, animated: true)
    }

}

extension TransactionsHeaderView: ITransactionsCoinSelectDelegate {

    func didSelect(configuredToken: ConfiguredToken?) {
        viewModel.onSelect(configuredToken: configuredToken)
    }

}
