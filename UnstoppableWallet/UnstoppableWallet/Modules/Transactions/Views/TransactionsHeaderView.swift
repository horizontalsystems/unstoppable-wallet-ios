import UIKit
import SnapKit
import RxSwift
import UIExtensions
import ThemeKit
import ComponentKit
import MarketKit

class TransactionsHeaderView: UIView {
    static let height: CGFloat = .heightSingleLineCell

    private let viewModel: TransactionsViewModel
    private let disposeBag = DisposeBag()
    weak var viewController: UIViewController?

    private let blockchainButton = SecondaryButton()
    private let tokenButton = SecondaryButton()

    init(viewModel: TransactionsViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        backgroundColor = .themeNavigationBarBackground

        addSubview(blockchainButton)
        blockchainButton.snp.makeConstraints { maker in
            maker.leading.centerY.equalToSuperview()
        }

        blockchainButton.set(style: .transparent, image: UIImage(named: "arrow_small_down_20"))
        blockchainButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        blockchainButton.addTarget(self, action: #selector(onTapBlockchainButton), for: .touchUpInside)

        addSubview(tokenButton)
        tokenButton.snp.makeConstraints { maker in
            maker.trailing.centerY.equalToSuperview()
        }

        tokenButton.set(style: .transparent, image: UIImage(named: "arrow_small_down_20"))
        tokenButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tokenButton.addTarget(self, action: #selector(onTapTokenButton), for: .touchUpInside)

        let separatorView = UIView()

        addSubview(separatorView)
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
        let module = TransactionsCoinSelectModule.viewController(token: viewModel.token, delegate: self)
        viewController?.present(module, animated: true)
    }

}

extension TransactionsHeaderView: ITransactionsCoinSelectDelegate {

    func didSelect(token: Token?) {
        viewModel.onSelect(token: token)
    }

}
