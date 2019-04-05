import UIKit

class AboutCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var termsHeaderLabel: UILabel?
    @IBOutlet weak var termsLabel: UILabel?
    @IBOutlet weak var separatorView: UIView?

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorView?.backgroundColor = .cryptoSteel20
        titleLabel?.text = "guest.title".localized
        titleLabel?.textColor = .crypto_White_Black
        subtitleLabel?.text = "guest.subtitle".localized

        termsHeaderLabel?.text = "settings_about.terms_privacy_subtitle".localized
        termsLabel?.text = "settings_about.terms_privacy_text".localized
        termsLabel?.textColor = .crypto_Silver_Black
    }

}
