import UIKit

class SendButtonCell: UITableViewCell {
    private let sendButton: UIButton = .appYellow
    private var onTap: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none
        addSubview(sendButton)
        sendButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }
        sendButton.setTitle("send.confirmation.send_button".localized, for: .normal)
        sendButton.addTarget(self, action: #selector(onSendTouchUp), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(onTap: (() -> ())?) {
        self.onTap = onTap
    }

    @objc private func onSendTouchUp() {
        onTap?()
    }

}
