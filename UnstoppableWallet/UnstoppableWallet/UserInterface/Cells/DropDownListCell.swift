import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

protocol IDropDownListViewModel {
    var selectedItemDriver: Driver<String?> { get }
}

class DropDownListCell: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()
    private let viewModel: IDropDownListViewModel
    private let title: String

    var showList: (() -> ())? = nil

    init(viewModel: IDropDownListViewModel, title: String) {
        self.viewModel = viewModel
        self.title = title

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true

        subscribe(disposeBag, viewModel.selectedItemDriver) { [weak self] item in self?.sync(item: item) }
    }

    private func sync(item: String?) {
        CellBuilderNew.buildStatic(cell: self, rootElement: .hStack([
            .text { [weak self] component in
                component.font = .body
                component.textColor = .themeLeah
                component.text = self?.title ?? "n/a".localized
            },
            .secondaryButton { component in
                component.button.set(style: .default, image: UIImage(named: "arrow_small_down_20"))
                component.button.setTitle(item, for: .normal)
                component.onTap = { [weak self] in
                    self?.showList?()
                }
            }
        ]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
