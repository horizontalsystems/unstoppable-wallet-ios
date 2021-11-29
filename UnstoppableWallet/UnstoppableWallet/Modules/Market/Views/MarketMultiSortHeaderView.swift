import UIKit
import UIExtensions
import ThemeKit
import SnapKit
import ComponentKit

class MarketMultiSortHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let viewModel: MarketMultiSortHeaderViewModel
    weak var viewController: UIViewController?

    private let sortButton = ThemeButton()

    init(viewModel: MarketMultiSortHeaderViewModel, hasTopSelector: Bool = false, hasTopSeparator: Bool = true) {
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
            maker.top.bottom.equalToSuperview()
        }

        sortButton.apply(style: .secondaryTransparentIcon)
        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        sortButton.setImage(UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray), for: .normal)
        sortButton.setImage(UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray50), for: .highlighted)

        syncSortButtonTitle()
        sortButton.addTarget(self, action: #selector(tapSortButton), for: .touchUpInside)

        let marketFieldSelector = SelectorButton()

        contentView.addSubview(marketFieldSelector)
        marketFieldSelector.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        marketFieldSelector.set(items: viewModel.marketFields)
        marketFieldSelector.setSelected(index: viewModel.marketFieldIndex)
        marketFieldSelector.onSelect = { [weak self] index in
            self?.viewModel.onSelectMarketField(index: index)
        }

        if hasTopSelector {
            let marketTopSelector = SelectorButton()

            contentView.addSubview(marketTopSelector)
            marketTopSelector.snp.makeConstraints { maker in
                maker.trailing.equalTo(marketFieldSelector.snp.leading).offset(-CGFloat.margin8)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(28)
            }

            marketTopSelector.set(items: viewModel.marketTops)
            marketTopSelector.setSelected(index: viewModel.marketTopIndex)
            marketTopSelector.onSelect = { [weak self] index in
                self?.viewModel.onSelectMarketTop(index: index)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapSortButton() {
        let alertController = AlertRouter.module(
                title: "market.sort_by".localized,
                viewItems: viewModel.sortingFields.enumerated().map { (index, sortingField) in
                    AlertViewItem(text: sortingField, selected: index == viewModel.sortingFieldIndex)
                }
        ) { [weak self] index in
            self?.viewModel.onSelectSortingField(index: index)
            self?.syncSortButtonTitle()
        }

        viewController?.present(alertController, animated: true)
    }

    private func syncSortButtonTitle() {
        sortButton.setTitle(viewModel.sortingFields[viewModel.sortingFieldIndex], for: .normal)
    }

}
