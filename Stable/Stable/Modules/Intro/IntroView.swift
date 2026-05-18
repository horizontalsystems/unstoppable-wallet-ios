import SwiftUI

struct IntroView: View {
    var onFinish: () -> Void

    @State private var scrollProgress: CGFloat = 0
    @State private var scrolledID: Int? = 0

    private let slides: [Slide] = [
        .init(title: "intro.slide1.title", subtitle: "intro.slide1.subtitle", image: "intro1"),
        .init(title: "intro.slide2.title", subtitle: "intro.slide2.subtitle", image: "intro2"),
        .init(title: "intro.slide3.title", subtitle: "intro.slide3.subtitle", image: "intro3"),
    ]

    var body: some View {
        ThemeView {
            GeometryReader { geo in
                let width = geo.size.width

                ZStack {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, _ in
                        Image(slides[index].image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(opacity(for: index, progress: scrollProgress))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                                VStack {
                                    Spacer()

                                    VStack(spacing: 12) {
                                        ThemeText(key: slide.title, style: .title3B)
                                            .multilineTextAlignment(.center)

                                        ThemeText(key: slide.subtitle, style: .subhead, color: .themeGray)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.horizontal, 48)
                                    .padding(.bottom, 162)
                                }
                                .frame(width: width)
                                .id(index)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $scrolledID)
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.x
                    } action: { _, newOffset in
                        guard width > 0 else { return }
                        scrollProgress = newOffset / width
                    }

                    VStack(spacing: 48) {
                        Spacer()

                        HStack(spacing: 12) {
                            ForEach(0 ..< slides.count, id: \.self) { index in
                                Capsule()
                                    .fill((scrolledID ?? 0) == index ? Color.themeLime : Color.andy)
                                    .frame(size: 10)
                                    .animation(.spring(response: 0.3), value: scrolledID)
                                    .onTapGesture {
                                        withAnimation {
                                            scrolledID = index
                                        }
                                    }
                            }
                        }

                        ThemeButton(text: "intro.get_started") {
                            onFinish()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
    }

    private func opacity(for index: Int, progress: CGFloat) -> Double {
        let distance = abs(progress - CGFloat(index))
        return Double(max(0, 1 - distance))
    }
}

extension IntroView {
    struct Slide: Identifiable {
        let id = UUID()
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
        let image: String
    }
}
