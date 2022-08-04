import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import RxSwift
import RxCocoa

protocol IDropdownFilterHeaderViewModel: AnyObject {
    var dropdownTitle: String { get }
    var dropdownViewItems: [AlertViewItem] { get }
    var dropdownValueDriver: Driver<String> { get }
    func onSelectDropdown(index: Int)
}

class DropdownFilterHeaderView: UITableViewHeaderFooterView {
    private let viewModel: IDropdownFilterHeaderViewModel
    private let disposeBag = DisposeBag()

    weak var viewController: UIViewController?

    private let dropdownButton = SecondaryButton()

    init(viewModel: IDropdownFilterHeaderViewModel, hasTopSeparator: Bool = true) {
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

        subscribe(disposeBag, viewModel.dropdownValueDriver) { [weak self] in self?.syncDropdownButton(title: $0) }
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

    private func syncDropdownButton(title: String) {
        dropdownButton.setTitle(title, for: .normal)
    }

}
