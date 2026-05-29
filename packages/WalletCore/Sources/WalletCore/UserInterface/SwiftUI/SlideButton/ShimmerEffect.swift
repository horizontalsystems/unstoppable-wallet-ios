import SwiftUI

// Credit to: https://github.com/markiv/SwiftUI-Shimmer
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 1

    let animation = Animation.linear(duration: 4).repeatForever(autoreverses: false)

    func body(content: Content) -> some View {
        content
            .modifier(AnimatedMask(phase: phase).animation(animation))
            .onAppear {
                phase = -0.2
            }
    }
}

struct AnimatedMask: AnimatableModifier {
    var phase: CGFloat = 0

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask(mask.scaleEffect(3))
    }

    private var mask: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.black, location: phase),
                .init(color: Color.black.opacity(0.3), location: phase + 0.1),
                .init(color: Color.black, location: phase + 0.2),
            ]),
            startPoint: .bottomTrailing,
            endPoint: .topLeading
        )
    }
}

extension View {
    @ViewBuilder func shimmerEffect(_ active: Bool = true) -> some View {
        if active {
            modifier(ShimmerEffect())
        } else {
            self
        }
    }
}

struct ShimmerEffect_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
            .modifier(ShimmerEffect())
    }
}
