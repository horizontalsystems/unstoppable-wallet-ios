import UIKit

class SwapInputAccessoryView: UIView {
    private let separatorView = UIView()
    private let autocompleteView = FilterHeaderView(buttonStyle: .default)

    private var heightConstraint: NSLayoutConstraint?
    var heightValue: CGFloat = 0 {
        didSet {
            heightConstraint?.constant = heightValue
        }
    }

    var onSelect: ((Decimal) -> ())?

    override public init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }
        separatorView.backgroundColor = .themeSteel20

        addSubview(autocompleteView)
        autocompleteView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(FilterHeaderView.height)
        }

        autocompleteView.autoDeselect = true
        autocompleteView.reload(filters: [
            FilterHeaderView.ViewItem.item(title: "25%"),
            FilterHeaderView.ViewItem.item(title: "50%"),
            FilterHeaderView.ViewItem.item(title: "75%"),
            FilterHeaderView.ViewItem.item(title: "100%"),
        ])
        autocompleteView.onSelect = {[weak self] in self?.onTap(at: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()

        var heightConstraint: NSLayoutConstraint?

        for constraint in constraints {
            if constraint.firstItem as? UIView == self, constraint.firstAttribute == .height, constraint.relation == .equal {
                heightConstraint = constraint
                break
            }
        }

        self.heightConstraint = heightConstraint
        self.heightConstraint?.constant = heightValue
    }

    private func onTap(at index: Int) {
        let multi = 0.25 * Decimal(index + 1)
        onSelect?(multi)
    }

}
