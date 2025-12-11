import SwiftUI

struct DefenceSystemCell: View {
    var body: some View {
        HStack(spacing: .margin8) {
            ThemeImage(ComponentImage.init(image: "defense_filled"), size: .iconSize20)
            ThemeText("defense_cell.title".localized, style: .subhead, colorStyle: .primary)
            Spacer()
        }
    }
}
