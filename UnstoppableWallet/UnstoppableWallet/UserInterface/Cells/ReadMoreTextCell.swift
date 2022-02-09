import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class ReadMoreTextCell: BaseThemeCell {
    private static let collapsedHeight: CGFloat = 160
    private static let readMoreButtonOverlayHeight: CGFloat = 37
    private static let horizontalPadding: CGFloat = .margin24
    private static let verticalPadding: CGFloat = .margin12
    private static let gradientOffset: CGFloat = -.margin6
    private static let buttonHeight: CGFloat = 33

    private let labelWrapper = GradientClippingView(clippingHeight: .margin16)
    private let readMoreTextView = MarkdownTextView()
    private let collapseButtonBackground = UIView()
    private let collapseButton = UIButton()

    private var collapsed = true
    private var expandable = true
    private var containerWidth: CGFloat = 0 {
        didSet {
            updateLayout()
        }
    }

    var onTapLink: ((URL) -> ())?
    var onChangeHeight: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(labelWrapper)
        labelWrapper.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(ReadMoreTextCell.verticalPadding)
            maker.leading.trailing.equalToSuperview().inset(ReadMoreTextCell.horizontalPadding)
        }

        labelWrapper.addSubview(readMoreTextView)
        readMoreTextView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
        }

        readMoreTextView.delegate = self

        contentView.addSubview(collapseButtonBackground)
        collapseButtonBackground.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(30)
        }

        collapseButtonBackground.backgroundColor = .themeTyler

        contentView.addSubview(collapseButton)
        collapseButton.snp.makeConstraints { maker in
            maker.top.equalTo(labelWrapper.snp.bottom).offset(ReadMoreTextCell.verticalPadding)
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(ReadMoreTextCell.buttonHeight)
        }

        collapseButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
        collapseButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -.margin8, bottom: 0, right: -.margin8)

        collapseButton.setTitle("chart.about.read_more".localized, for: .normal)
        collapseButton.setTitleColor(.themeYellowD, for: .normal)
        collapseButton.titleLabel?.font = .subhead2
        collapseButton.addTarget(self, action: #selector(onTapCollapse), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapCollapse() {
        collapsed = !collapsed
        collapseButton.setTitle(collapsed ? "chart.about.read_more".localized : "chart.about.read_less".localized, for: .normal)
        labelWrapper.isClipping = collapsed

        onChangeHeight?()
    }

    var contentText: NSAttributedString? {
        get { readMoreTextView.attributedText }
        set {
            readMoreTextView.attributedText = newValue
            updateLayout()
        }
    }

    private var textHeight: CGFloat {
        readMoreTextView.attributedText?.height(containerWidth: containerWidth - 2 * ReadMoreTextCell.horizontalPadding) ?? 0
    }

    func cellHeight(containerWidth: CGFloat) -> CGFloat {
        self.containerWidth = containerWidth

        let labelHeight = collapsed ? min(Self.collapsedHeight, textHeight) : textHeight
        return labelHeight + 2 * ReadMoreTextCell.verticalPadding + (expandable ? ReadMoreTextCell.buttonHeight : 0)
    }

    private func updateLayout() {
        guard textHeight > 0, containerWidth > 0 else {
            return
        }

        if textHeight <= (Self.collapsedHeight + Self.readMoreButtonOverlayHeight), expandable {
            collapseButton.snp.removeConstraints()
            labelWrapper.snp.remakeConstraints { maker in
                maker.top.bottom.equalToSuperview().inset(ReadMoreTextCell.verticalPadding)
                maker.leading.trailing.equalToSuperview().inset(ReadMoreTextCell.horizontalPadding)
            }

            collapseButtonBackground.isHidden = true
            collapseButton.isHidden = true
            labelWrapper.isClipping = false
            expandable = false
            if textHeight >= (Self.collapsedHeight) {
                collapsed = false
            }
        } else if textHeight > (Self.collapsedHeight + Self.readMoreButtonOverlayHeight), !expandable {
            labelWrapper.snp.remakeConstraints { maker in
                maker.top.equalToSuperview().inset(ReadMoreTextCell.verticalPadding)
                maker.leading.trailing.equalToSuperview().inset(ReadMoreTextCell.horizontalPadding)
            }
            collapseButton.snp.remakeConstraints { maker in
                maker.top.equalTo(labelWrapper.snp.bottom).offset(ReadMoreTextCell.verticalPadding)
                maker.trailing.equalToSuperview()
                maker.bottom.equalToSuperview()
                maker.height.equalTo(ReadMoreTextCell.buttonHeight)
            }

            collapseButtonBackground.isHidden = false
            collapseButton.isHidden = false
            expandable = true
        }
    }

}

extension ReadMoreTextCell: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        onTapLink?(URL)
        return true
    }

}
