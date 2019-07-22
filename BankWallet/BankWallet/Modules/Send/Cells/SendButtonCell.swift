import UIKit

class SendButtonCell: UITableViewCell {

    let button = RespondButton()

    private var item: SButtonItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(button)
        button.onTap = { [weak self] in
            self?.item?.delegate?.onSendClicked()
        }

        button.backgrounds = ButtonTheme.yellowBackgroundDictionary
        button.textColors = ButtonTheme.textColorDictionary
        button.titleLabel.text = "send.send_button".localized
        button.cornerRadius = SendTheme.sendButtonCornerRadius

        button.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.bottom.equalToSuperview().offset(-SendTheme.margin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.height.equalTo(SendTheme.sendButtonHeight)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: SButtonItem) {
        self.item = item
        item.bind = { [weak self] in
            self?.bind()
        }
        bind()
    }

    func bind() {
        if let item = item {
            button.state = item.sendButtonEnabled ? .active : .disabled
        }
    }

}
