import UIKit
import UIExtensions
import ThemeKit
import SnapKit
import ComponentKit

protocol IMarketMultiSortHeaderViewModel {
    var sortItems: [String] { get }
    var sortIndex: Int { get }

    var leftSelectorItems: [String] { get }
    var leftSelectorIndex: Int { get }

    var rightSelectorItems: [String] { get }
    var rightSelectorIndex: Int { get }

    func onSelectSort(index: Int)
    func onSelectLeft(index: Int)
    func onSelectRight(index: Int)
}

class MarketMultiSortHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let viewModel: IMarketMultiSortHeaderViewModel
    weak var viewController: UIViewController?

    private let sortButton = SecondaryButton()

    init(viewModel: IMarketMultiSortHeaderViewModel, hasLeftSelector: Bool = false, hasTopSeparator: Bool = true) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        if hasTopSeparator {
            let separatorView = UIView()
            contentView.addSubview(separatorView)
            separatorView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalToSuperview()
                maker.height.equalTo(CGFloat.heightOnePixel)
            }

            separatorView.backgroundColor = .themeSteel20
        }

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        sortButton.set(style: .transparent)
        sortButton.set(image: UIImage(named: "arrow_small_down_20"))
        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        syncSortButtonTitle()
        sortButton.addTarget(self, action: #selector(tapSortButton), for: .touchUpInside)

        let rightSelector = SelectorButton()

        contentView.addSubview(rightSelector)
        rightSelector.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        rightSelector.set(items: viewModel.rightSelectorItems)
        rightSelector.setSelected(index: viewModel.rightSelectorIndex)
        rightSelector.onSelect = { [weak self] index in
            self?.viewModel.onSelectRight(index: index)
        }

        if hasLeftSelector {
            let leftSelector = SelectorButton()

            contentView.addSubview(leftSelector)
            leftSelector.snp.makeConstraints { maker in
                maker.trailing.equalTo(rightSelector.snp.leading).offset(-CGFloat.margin8)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(28)
            }

            leftSelector.set(items: viewModel.leftSelectorItems)
            leftSelector.setSelected(index: viewModel.leftSelectorIndex)
            leftSelector.onSelect = { [weak self] index in
                self?.viewModel.onSelectLeft(index: index)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapSortButton() {
        let alertController = AlertRouter.module(
                title: "market.sort_by".localized,
                viewItems: viewModel.sortItems.enumerated().map { (index, sortingField) in
                    AlertViewItem(text: sortingField, selected: index == viewModel.sortIndex)
                }
        ) { [weak self] index in
            self?.viewModel.onSelectSort(index: index)
            self?.syncSortButtonTitle()
        }

        viewController?.present(alertController, animated: true)
    }

    private func syncSortButtonTitle() {
        sortButton.setTitle(viewModel.sortItems[viewModel.sortIndex], for: .normal)
    }

}
