import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionNoteItemView: BaseActionItemView {

    private let noteLabel = UILabel()
    private let imageView = UIImageView()
    private let actionButton = UIButton()

    override var item: TransactionNoteItem? { return _item as? TransactionNoteItem }

    override func initView() {
        super.initView()

        backgroundColor = .appLawrence

        addSubview(noteLabel)
        addSubview(imageView)
        addSubview(actionButton)

        imageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.size.equalTo(16)
        }
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        noteLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(imageView.snp.trailing).offset(11)
        }

        noteLabel.font = .appSubhead2
        noteLabel.textColor = .appGray
        noteLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        noteLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        noteLabel.numberOfLines = 0

        actionButton.snp.makeConstraints { maker in
            maker.leading.equalTo(noteLabel.snp.trailing)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(0)
        }

        actionButton.addTarget(self, action: #selector(onActionClicked), for: .touchUpInside)
    }

    @objc func onActionClicked() {
        item?.onTap?()
    }

    override func updateView() {
        super.updateView()

        noteLabel.text = item?.note
        imageView.image = item.flatMap { UIImage(named: $0.imageName) }

        if let iconName = item?.iconName {
            actionButton.setImage(UIImage(named: iconName)?.tinted(with: .appJacob), for: .normal)
            actionButton.snp.updateConstraints { maker in
                maker.trailing.equalToSuperview()
                maker.width.equalTo(24 + CGFloat.margin4x + CGFloat.margin2x)
            }
        } else {
            actionButton.snp.updateConstraints { maker in
                maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
                maker.width.equalTo(0)
            }
        }
    }

}
