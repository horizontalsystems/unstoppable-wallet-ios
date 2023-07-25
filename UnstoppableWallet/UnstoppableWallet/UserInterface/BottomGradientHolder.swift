import UIKit
import UIExtensions
import SnapKit

protocol IHeightAwareView {
    var height: CGFloat { get }
}

class BottomGradientHolder: GradientView {
    static let defaultStackViewInsets = UIEdgeInsets(top: .margin16 + .margin24, left: 0, bottom: .margin16, right: 0)
    let stackView = UIStackView()

    private let insets: UIEdgeInsets

    private var position: Position?
    private var keyboardAwareViewController: KeyboardAwareViewController?

    init(insets: UIEdgeInsets = BottomGradientHolder.defaultStackViewInsets) {
        self.insets = insets

        let holderBackground: UIColor = .themeTyler
        super.init(gradientHeight: .margin24, fromColor: holderBackground.withAlphaComponent(0), toColor: holderBackground)

        super.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(insets.top)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(insets.bottom)
        }

        stackView.axis = .vertical
        stackView.spacing = .margin16
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var stackHeight: CGFloat {
        stackView.height
    }

    private func remakeConstraints(tableView: UITableView? = nil) {
        if let tableView {
            position = .bottom
            snp.remakeConstraints { make in
                make.top.equalTo(tableView.snp.bottom).offset(-insets.top)
                make.leading.trailing.bottom.equalToSuperview()
            }
            // try to avoid case, when bottom holder bind to tableview but keyboardViewController rewrite insets (ChooseWatchVC)
            if let keyboardAwareViewController,
               keyboardAwareViewController.accessoryView != self {
                keyboardAwareViewController.additionalInsetsOnlyForClosedKeyboard = true    // add bottom height only when closed keyboard
                keyboardAwareViewController.additionalContentInsets = .init(top: 0, left: 0, bottom: insets.top, right: 0)
            } else { // otherwise just setup insets
                tableView.contentInset.bottom = insets.top
            }
        } else {
            position = .floating
            snp.remakeConstraints { make in
                make.height.equalTo(height).priority(.high)
                make.leading.trailing.bottom.equalToSuperview()
            }

            // we must use self size as inset when keyboard is closed if it's keyboardAwareViewController
            // only when bottom view is not accessory view (not handling automatic)
            if let keyboardAwareViewController,
               keyboardAwareViewController.accessoryView != self {
                    keyboardAwareViewController.additionalInsetsOnlyForClosedKeyboard = true    // add bottom height only when closed keyboard
                    keyboardAwareViewController.additionalContentInsets = .init(top: 0, left: 0, bottom: height, right: 0)
            }
        }
    }

}

extension BottomGradientHolder {

    override func addSubview(_ view: UIView) {
        guard let position else {
            fatalError("Before add views need to set position by add(to:_) method")
        }
        stackView.addArrangedSubview(view)
        stackView.layoutIfNeeded()

        if position == .floating {
            remakeConstraints()                 // update constraints only for floating holder
        }
    }


    func add(to viewController: UIViewController, under tableView: UITableView? = nil) {
        viewController.view.addSubview(self)
        if let viewController = viewController as? KeyboardAwareViewController {
            keyboardAwareViewController = viewController
        }   // we need to handle additionalInsets when working with keyboardAware controller

        remakeConstraints(tableView: tableView)
    }

    override var height: CGFloat {
        insets.height + stackHeight
    }

}

extension BottomGradientHolder {

    enum Position {
        case bottom
        case floating
    }

}