import Foundation
import UIKit

class SectionSpinnerView: UITableViewHeaderFooterView {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    func bind() {
        activityIndicator.startAnimating()
    }

}
