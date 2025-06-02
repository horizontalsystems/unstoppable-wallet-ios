import SkeletonView
import SnapKit
import ThemeKit
import UIKit

open class BaseThemeCell: UITableViewCell {
    public static let leftInset: CGFloat = .margin16
    public static let rightInset: CGFloat = .margin16
    public static let middleInset: CGFloat = .margin16

    public let wrapperView = BorderedView()
    public let topSeparatorView = UIView()

    let stackView = UIStackView()
    var rootView: UIView?

    public var isVisible = true
    var id: String?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        isSkeletonable = true

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        separatorInset.left = 0
        selectionStyle = .none

        clipsToBounds = true
        layer.cornerCurve = .continuous

        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        wrapperView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        wrapperView.addSubview(topSeparatorView)
        topSeparatorView.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        stackView.insetsLayoutMarginsFromSafeArea = false

        wrapperView.borderWidth = .heightOneDp
        topSeparatorView.backgroundColor = .themeSteel10
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open var cellHeight: CGFloat {
        isVisible ? .heightSingleLineCell : 0
    }

    func corners(isFirst: Bool, isLast: Bool) -> CACornerMask {
        var maskedCorners: CACornerMask = []
        if isFirst {
            maskedCorners.insert(.layerMinXMinYCorner)
            maskedCorners.insert(.layerMaxXMinYCorner)
        }
        if isLast {
            maskedCorners.insert(.layerMinXMaxYCorner)
            maskedCorners.insert(.layerMaxXMaxYCorner)
        }
        return maskedCorners
    }

    open func set(backgroundStyle: BackgroundStyle, cornerRadius: CGFloat = .cornerRadius12, isFirst: Bool = false, isLast: Bool = false) {
        var maskedCorners: CACornerMask = []
        var resolvedCornerRadius: CGFloat = 0

        wrapperView.borders = []
        wrapperView.borderWidth = 0
        wrapperView.cornerRadius = 0

        switch backgroundStyle {
        case .lawrence:
            if isFirst || isLast {
                resolvedCornerRadius = cornerRadius
            }
            maskedCorners = corners(isFirst: isFirst, isLast: isLast)

            topSeparatorView.isHidden = isFirst
            wrapperView.backgroundColor = .themeLawrence
            wrapperView.borderColor = .clear
        case .bordered, .externalBorderOnly, .borderedLawrence:
            var borderColor = UIColor.themeSteel20

            var borders: UIRectEdge = [.left, .right]
            if isFirst || isLast {
                resolvedCornerRadius = cornerRadius
            }
            maskedCorners = corners(isFirst: isFirst, isLast: isLast)
            if isFirst {
                borders.formUnion(.top)
            }
            if isLast {
                borders.formUnion(.bottom)
            }

            topSeparatorView.snp.remakeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(CGFloat.heightOneDp)
                maker.top.equalToSuperview()
                maker.height.equalTo(CGFloat.heightOneDp)
            }

            topSeparatorView.isHidden = isFirst || backgroundStyle == .externalBorderOnly
            if case let .borderedLawrence(color) = backgroundStyle {
                borderColor = color
                wrapperView.backgroundColor = .themeLawrence
            } else {
                wrapperView.backgroundColor = .clear
            }
            wrapperView.borderWidth = .heightOneDp
            wrapperView.borders = borders
            wrapperView.cornerRadius = resolvedCornerRadius
            wrapperView.borderColor = borderColor
        case .transparent:
            var borders: UIRectEdge = []
            if !isFirst {
                borders.formUnion(.top)
            }
            if isLast {
                borders.formUnion(.bottom)
            }

            topSeparatorView.isHidden = true
            wrapperView.backgroundColor = .clear
            wrapperView.borderColor = .themeSteel10
            wrapperView.borderWidth = .heightOneDp
            wrapperView.borders = borders
        }

        wrapperView.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview().inset(Self.margin(backgroundStyle: backgroundStyle))
        }

        wrapperView.cornerRadius = resolvedCornerRadius
        wrapperView.layer.maskedCorners = maskedCorners
    }

    public func bind(rootElement: CellBuilderNew.CellElement) {
        guard let rootView else {
            return
        }

        rootElement.bind(view: rootView)
    }

    public func bind<T>(index: Int, block: (T) -> Void) {
        guard index < stackView.arrangedSubviews.count, let view = stackView.arrangedSubviews[index] as? T else {
            print("Cannot cast component view: \(T.self)")
            return
        }

        block(view)
    }

    public func component<T>(index: Int) -> T? {
        guard index < stackView.arrangedSubviews.count, let view = stackView.arrangedSubviews[index] as? T else {
            print("Cannot cast component view: \(T.self)")
            return nil
        }

        return view
    }

    public static func margin(backgroundStyle: BackgroundStyle) -> UIEdgeInsets {
        switch backgroundStyle {
        case .lawrence, .bordered, .externalBorderOnly, .borderedLawrence:
            return UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
        case .transparent:
            return UIEdgeInsets.zero
        }
    }

    public enum BackgroundStyle: Equatable {
        case lawrence
        case borderedLawrence(UIColor)
        case bordered
        case externalBorderOnly
        case transparent

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.lawrence, .lawrence): return true
            case (.bordered, .bordered): return true
            case (.externalBorderOnly, .externalBorderOnly): return true
            case (.transparent, .transparent): return true
            case let (.borderedLawrence(lhsColor), .borderedLawrence(rhsColor)): return lhsColor == rhsColor
            default: return false
            }
        }
    }
}
