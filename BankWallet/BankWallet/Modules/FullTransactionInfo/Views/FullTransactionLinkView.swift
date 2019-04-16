import UIKit
import SnapKit
import UIExtensions

class FullTransactionLinkView: UIView {
    let linkWrapper = RespondView()
    let linkLabel = UILabel()

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear

        addSubview(linkWrapper)
        linkWrapper.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        linkWrapper.addSubview(linkLabel)
        linkLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        linkLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        linkLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalToSuperview().offset(FullTransactionInfoTheme.linkCellHorizontalMargin)
            maker.trailing.equalToSuperview().offset(-FullTransactionInfoTheme.linkCellHorizontalMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String, onTap: (() -> ())? = nil) {
        let attributedString = NSAttributedString(string: text, attributes: [.font: FullTransactionInfoTheme.linkLabelFont,
                                                                             .foregroundColor: FullTransactionInfoTheme.linkLabelColor,
                                                                             .underlineStyle: FullTransactionInfoTheme.linkLabelUnderlineStyle,
                                                                             .underlineColor: FullTransactionInfoTheme.linkLabelColor])
        linkLabel.attributedText = attributedString
        linkWrapper.handleTouch = onTap
    }

}
