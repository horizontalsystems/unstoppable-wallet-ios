import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

class DropDownListCell: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()
    private let viewModel: DropDownListViewModel
    private let title: String

    weak var sourceViewController: UIViewController?

    init(viewModel: DropDownListViewModel, title: String) {
        self.viewModel = viewModel
        self.title = title

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true

        sync(item: nil)
        subscribe(disposeBag, viewModel.selectedItemDriver) { [weak self] item in
            self?.sync(item: item)
        }
    }

    private func sync(item: String?) {
        CellBuilderNew.buildStatic(cell: self, rootElement: .hStack([
            .text { [weak self] component in
                component.font = .subhead2
                component.textColor = .themeGray
                component.text = self?.title ?? "n/a".localized
            },
            .secondaryButton { component in
                component.button.set(style: .default)
                component.button.set(image: UIImage(named: "arrow_small_down_20"))
                component.button.setTitle(item, for: .normal)
                component.onTap = { [weak self] in
                    self?.onTapList()
                }
            }
        ]))

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onTapList() {
//        let alertController = AlertRouter.module(
//                title: "send.tx_speed".localized,
//                viewItems: viewModel.itemsList
//        ) { [weak self] index in
//            self?.viewModel.onSelect(index)
//        }
//
//        sourceViewController?.present(alertController, animated: true)
    }

}
