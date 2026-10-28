import SwiftUI

struct CoverView: View {
    private static let imageAspect: CGFloat = 1125 / 1056

    var body: some View {
        ThemeRadialView {
            GeometryReader { geo in
                ThemeImage(
                    ComponentImage(image: "Intro - Stay Private", contentMode: .fit),
                    size: CGSize(width: geo.size.width, height: geo.size.width / Self.imageAspect)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
