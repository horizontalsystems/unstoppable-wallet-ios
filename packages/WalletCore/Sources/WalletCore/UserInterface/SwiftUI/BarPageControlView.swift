import SwiftUI

struct BarPageControlView: View {
    static let barSize = CGSize(width: 20, height: 4)

    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: .margin4) {
            ForEach(0 ..< pageCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: .cornerRadius2, style: .continuous)
                    .fill(index == currentPage ? Color.themeJacob : Color.themeBlade)
                    .frame(width: Self.barSize.width, height: Self.barSize.height)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }
}
