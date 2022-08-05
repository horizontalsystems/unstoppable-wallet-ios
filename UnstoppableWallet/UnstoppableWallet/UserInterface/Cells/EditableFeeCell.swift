import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

protocol IEditableFeeViewModel: IFeeViewModel {
    var editButtonVisibleDriver: Driver<Bool> { get }
    var editButtonHighlightedDriver: Driver<Bool> { get }
}

class EditableFeeCell: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()

    private let viewModel: IEditableFeeViewModel

    init(viewModel: IEditableFeeViewModel, isFirst: Bool = true, isLast: Bool = true) {
        self.viewModel = viewModel
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true
        set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

        CellBuilder.build(cell: self, elements: [.text, .text, .margin8, .image20, .spinner20])

        bind(index: 0) { (component: TextComponent) in
            component.font = .subhead2
            component.textColor = .themeGray
            component.text = "send.fee".localized
        }

        bind(index: 2) { (component: ImageComponent) in
            component.imageView.image =  UIImage(named: "edit2_20")?.withRenderingMode(.alwaysTemplate)
        }

        subscribe(disposeBag, viewModel.valueDriver) { [weak self] value in
            self?.bind(index: 1) { (component: TextComponent) in
                if let value = value {
                    component.isHidden = false
                    component.font = .subhead1
                    component.textColor = value.type.textColor
                    component.text = value.text
                } else {
                    component.isHidden = true
                }
            }
        }

        subscribe(disposeBag, viewModel.editButtonVisibleDriver) { [weak self] visible in
            self?.selectionStyle = visible ? .default : .none
            self?.bind(index: 2) { (component: ImageComponent) in
                component.isHidden = !visible
            }
        }

        subscribe(disposeBag, viewModel.editButtonHighlightedDriver) { [weak self] highlighted in
            self?.bind(index: 2) { (component: ImageComponent) in
                component.imageView.tintColor = highlighted ? .themeJacob : .themeGray
            }
        }

        subscribe(disposeBag, viewModel.spinnerVisibleDriver) { [weak self] visible in
            self?.bind(index: 3) { (component: SpinnerComponent) in
                component.isHidden = !visible
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
