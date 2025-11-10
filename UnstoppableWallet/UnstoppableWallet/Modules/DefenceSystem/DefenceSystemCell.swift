import SwiftUI

struct DefenceSystemCell: View {
    var body: some View {
        Cell(
            style: .secondary,
            left: {
                Image("defense_filled")
                    .frame(size: .iconSize20)
            },
            middle: {
                ThemeText("defense_cell.title".localized, style: .subhead, colorStyle: .primary)
            }
        )
    }
}
