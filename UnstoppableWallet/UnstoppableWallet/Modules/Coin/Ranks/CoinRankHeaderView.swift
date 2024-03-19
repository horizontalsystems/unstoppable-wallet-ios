import ComponentKit
import RxCocoa
import RxSwift
import SnapKit
import ThemeKit
import UIExtensions
import UIKit

class CoinRankHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let viewModel: CoinRankViewModel
    private let disposeBag = DisposeBag()

    private let sortButton = SecondaryCircleButton()

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

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        sortButton.addTarget(self, action: #selector(onTapSortButton), for: .touchUpInside)

        if let selectorItems = viewModel.selectorItems {
            let selector = SelectorButton()

            contentView.addSubview(selector)
            selector.snp.makeConstraints { maker in
                maker.trailing.equalToSuperview().inset(CGFloat.margin16)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(28)
            }

            selector.set(items: selectorItems)
            selector.setSelected(index: viewModel.selectorIndex)
            selector.onSelect = { [weak self] index in
                self?.viewModel.onSelectSelector(index: index)
            }
        }

        subscribe(disposeBag, viewModel.sortDirectionDriver) { [weak self] in self?.syncSortButton(ascending: $0) }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSortButton() {
        viewModel.onToggleSortDirection()
    }

    private func syncSortButton(ascending: Bool) {
        sortButton.set(image: UIImage(named: ascending ? "sort_l2h_20" : "sort_h2l_20"))
    }
}
