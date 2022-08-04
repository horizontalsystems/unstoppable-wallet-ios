import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import RxSwift
import RxCocoa

protocol IDropdownSortHeaderViewModel: AnyObject {
    var dropdownTitle: String { get }
    var dropdownViewItems: [AlertViewItem] { get }
    var dropdownValueDriver: Driver<String> { get }
    func onSelectDropdown(index: Int)

    var sortDirectionAscendingDriver: Driver<Bool> { get }
    func onToggleSortDirection()
}

class DropdownSortHeaderView: UITableViewHeaderFooterView {
    private let viewModel: IDropdownSortHeaderViewModel
    private let disposeBag = DisposeBag()

    weak var viewController: UIViewController?

    private let dropdownButton = SecondaryButton()
    private let sortButton = SecondaryCircleButton()

    init(viewModel: IDropdownSortHeaderViewModel, hasTopSeparator: Bool = true) {
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

        contentView.addSubview(dropdownButton)
        dropdownButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        dropdownButton.set(style: .transparent)
        dropdownButton.set(image: UIImage(named: "arrow_small_down_20"))
        dropdownButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dropdownButton.addTarget(self, action: #selector(onTapDropdownButton), for: .touchUpInside)

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        sortButton.addTarget(self, action: #selector(onTapSortButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.dropdownValueDriver) { [weak self] in self?.syncDropdownButton(title: $0) }
        subscribe(disposeBag, viewModel.sortDirectionAscendingDriver) { [weak self] in self?.syncSortButton(ascending: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapDropdownButton() {
        let alertController = AlertRouter.module(
                title: viewModel.dropdownTitle,
                viewItems: viewModel.dropdownViewItems
        ) { [weak self] index in
            self?.viewModel.onSelectDropdown(index: index)
        }

        viewController?.present(alertController, animated: true)
    }

    @objc private func onTapSortButton() {
        viewModel.onToggleSortDirection()
    }

    private func syncDropdownButton(title: String) {
        dropdownButton.setTitle(title, for: .normal)
    }

    private func syncSortButton(ascending: Bool) {
        sortButton.set(image: UIImage(named: ascending ? "arrow_medium_2_up_20" : "arrow_medium_2_down_20"))
    }

}
