import UIKit
import ThemeKit
import SnapKit

class ReadMoreTextCell: BaseThemeCell {
    private static let font: UIFont = .subhead2
    private static let collapsedNumberOfLines: Int = 8
    private static let horizontalPadding: CGFloat = .margin24
    private static let verticalPadding: CGFloat = .margin12
    private static let gradientOffset: CGFloat = -.margin6
    private static let buttonHeight: CGFloat = 33

    private let gradientView = BottomGradientHolder()
    private let labelWrapper = UIView()
    private let readMoreTextLabel = UILabel()
    private let collapseButton = UIButton()

    private var collapsed = true
    private var expandable = true
    private var containerWidth: CGFloat = 0 {
        didSet {
            updateLayout()
        }
    }

    var onChangeHeight: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(labelWrapper)
        labelWrapper.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(ReadMoreTextCell.verticalPadding)
            maker.leading.trailing.equalToSuperview().inset(ReadMoreTextCell.horizontalPadding)
        }

        labelWrapper.addSubview(readMoreTextLabel)
        readMoreTextLabel.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
        }

        readMoreTextLabel.font = ReadMoreTextCell.font
        readMoreTextLabel.textColor = .themeGray
        readMoreTextLabel.numberOfLines = 0
        readMoreTextLabel.lineBreakMode = .byTruncatingTail

        contentView.addSubview(gradientView)
        gradientView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(labelWrapper.snp.bottom).offset(ReadMoreTextCell.gradientOffset)
        }

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

        onChangeHeight?()
    }

    var contentText: String? {
        get { readMoreTextLabel.text }
        set {
            readMoreTextLabel.text = newValue
            updateLayout()
        }
    }

    private var textHeight: CGFloat {
        readMoreTextLabel.text?.height(forContainerWidth: containerWidth - 2 * ReadMoreTextCell.horizontalPadding, font: ReadMoreTextCell.font) ?? 0
    }

    private func collapsedLabelHeight(lines: Int) -> CGFloat {
        ceil(CGFloat(lines) * ReadMoreTextCell.font.lineHeight)
    }

    func cellHeight(containerWidth: CGFloat) -> CGFloat {
        self.containerWidth = containerWidth

        let labelHeight = collapsed ? min(collapsedLabelHeight(lines: ReadMoreTextCell.collapsedNumberOfLines), textHeight) : textHeight
        return labelHeight + 2 * ReadMoreTextCell.verticalPadding + (expandable ? ReadMoreTextCell.buttonHeight : 0)
    }

    private func updateLayout() {
        guard textHeight > 0, containerWidth > 0 else {
            return
        }

        if textHeight <= (collapsedLabelHeight(lines: Self.collapsedNumberOfLines + 2)), expandable {
            collapseButton.snp.removeConstraints()
            gradientView.snp.removeConstraints()
            labelWrapper.snp.remakeConstraints { maker in
                maker.top.bottom.equalToSuperview().inset(ReadMoreTextCell.verticalPadding)
                maker.leading.trailing.equalToSuperview().inset(ReadMoreTextCell.horizontalPadding)
            }

            collapseButton.isHidden = true
            gradientView.isHidden = true
            expandable = false
            if textHeight >= (collapsedLabelHeight(lines: Self.collapsedNumberOfLines)) {
                collapsed = false
            }
        } else if textHeight > (collapsedLabelHeight(lines: Self.collapsedNumberOfLines + 2)), !expandable {
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
            gradientView.snp.makeConstraints { maker in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.top.equalTo(labelWrapper.snp.bottom).offset(ReadMoreTextCell.gradientOffset)
            }

            collapseButton.isHidden = false
            gradientView.isHidden = false
            expandable = true
        }
    }

}
