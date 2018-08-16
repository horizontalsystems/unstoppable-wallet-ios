import UIKit
import GrouviExtensions

public class SectionColorHeader: UITableViewHeaderFooterView {

    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundView = UIView()
    }

}
