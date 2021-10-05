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
    private let marketFieldSelector = SelectorButton()

    init(viewModel: MarketMultiSortHeaderViewModel) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        let separatorView = UIView()
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        sortButton.apply(style: .secondaryTransparentIcon)
        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        sortButton.setImage(UIImage(named: "arrow_small_down_20"), for: .normal)
        sortButton.setImageTintColor(.themeGray, for: .normal)
        sortButton.setImageTintColor(.themeGray50, for: .highlighted)

        syncSortButtonTitle()
        sortButton.addTarget(self, action: #selector(tapSortButton), for: .touchUpInside)

        contentView.addSubview(marketFieldSelector)
        marketFieldSelector.snp.makeConstraints { maker in
            maker.leading.equalTo(sortButton.snp.trailing).priority(.high)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        marketFieldSelector.set(items: viewModel.marketFields)
        marketFieldSelector.setSelected(index: viewModel.marketFieldIndex)
        marketFieldSelector.onSelect = { [weak self] index in
            self?.viewModel.onSelectMarketField(index: index)
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
