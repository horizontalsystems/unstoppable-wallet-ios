import UIKit
import UIExtensions
import ThemeKit
import SnapKit
import ComponentKit

class CoinRankHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let viewModel: CoinRankViewModel

    init(viewModel: CoinRankViewModel) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        let separatorView = UIView()

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        let selector = SelectorButton()

        contentView.addSubview(selector)
        selector.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        selector.set(items: viewModel.selectorItems)
        selector.setSelected(index: viewModel.selectorIndex)
        selector.onSelect = { [weak self] index in
            self?.viewModel.onSelectSelector(index: index)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
