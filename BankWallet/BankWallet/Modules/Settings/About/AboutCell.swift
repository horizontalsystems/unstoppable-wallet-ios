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
        titleLabel?.text = "settings_about.app_title".localized
        titleLabel?.textColor = .crypto_White_Black
        subtitleLabel?.text = "settings_about.app_subtitle".localized

        termsHeaderLabel?.text = "settings_about.terms_privacy_subtitle".localized
        termsLabel?.text = "settings_about.terms_privacy_text".localized
        termsLabel?.textColor = .crypto_Silver_Black
    }

}
