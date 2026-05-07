import UIKit

public class ComponentKit {
    static var bundle: Bundle? {
        nil
    }

    public static func image(named: String) -> UIImage? {
        UIImage(named: named, in: nil, compatibleWith: nil)
    }
}
