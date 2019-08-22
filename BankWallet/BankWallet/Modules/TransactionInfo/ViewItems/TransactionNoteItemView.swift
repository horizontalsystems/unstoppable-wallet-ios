import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionNoteItemView: BaseActionItemView {

    var noteLabel = UILabel()

    override var item: TransactionNoteItem? { return _item as? TransactionNoteItem }

    override func initView() {
        super.initView()

        backgroundColor = TransactionInfoTheme.itemBackground

        noteLabel.font = TransactionInfoTheme.itemNoteFont
        noteLabel.textColor = TransactionInfoTheme.itemNoteColor
        noteLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        noteLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        noteLabel.numberOfLines = 0
        addSubview(noteLabel)
        noteLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
        }
    }

    override func updateView() {
        super.updateView()

        noteLabel.text = item?.note
    }

}
