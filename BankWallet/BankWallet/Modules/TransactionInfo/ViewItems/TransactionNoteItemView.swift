import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionNoteItemView: BaseActionItemView {

    var noteLabel = UILabel()

    override var item: TransactionNoteItem? { return _item as? TransactionNoteItem }

    override func initView() {
        super.initView()

        backgroundColor = .appLawrence

        addSubview(noteLabel)

        noteLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        noteLabel.font = .appSubhead2
        noteLabel.textColor = .appJacob
        noteLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        noteLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        noteLabel.numberOfLines = 0
    }

    override func updateView() {
        super.updateView()

        noteLabel.text = item?.note
    }

}
