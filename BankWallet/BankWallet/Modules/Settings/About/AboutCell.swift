import UIKit

class AboutCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var termsHeaderLabel: UILabel?
    @IBOutlet weak var termsLabel: UILabel?
    @IBOutlet weak var dependenciesHeaderLabel: UILabel?
    @IBOutlet weak var dependenciesLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel?.text = "guest.title".localized
        titleLabel?.textColor = .crypto_White_Black
        subtitleLabel?.text = "guest.subtitle".localized

        termsHeaderLabel?.text = "settings_about_terms_privacy_subtitle".localized
        termsLabel?.text = "settings_about_terms_privacy_text".localized
        termsLabel?.textColor = .crypto_Silver_Black

        dependenciesHeaderLabel?.text = "settings_about_dependencies_subtitle".localized
        dependenciesLabel?.text = "settings_about_dependencies_text".localized
        dependenciesLabel?.textColor = .crypto_Silver_Black
    }

}
