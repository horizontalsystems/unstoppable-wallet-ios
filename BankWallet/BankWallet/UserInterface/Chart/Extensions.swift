import UIKit

extension UIEdgeInsets {

    var width: CGFloat { return self.left + self.right }
    var height: CGFloat { return self.top + self.bottom }

}

extension Date {

    var startOfHour: Date {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: self)
        return Calendar.current.date(from: components)!
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components)!
    }

    func startOfMonth(ago: Int) -> Date {
        var components = DateComponents()
        components.month = -ago

        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }

}
