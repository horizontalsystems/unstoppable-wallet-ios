import SwiftUI

struct ScrollableTabHeaderView: View {
    let tabs: [String]

    @Binding var currentTabIndex: Int
    @Namespace var menuItemTransition

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color.themeSteel10)
                .frame(maxWidth: .infinity)
                .frame(height: 1)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .margin8) {
                        ForEach(tabs.indices, id: \.self) { index in
                            item(title: tabs[index], isActive: index == currentTabIndex, namespace: menuItemTransition)
                                .onTapGesture {
                                    withAnimation(.spring().speed(1.5)) {
                                        currentTabIndex = index
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, .margin12)
                }
                .onChange(of: currentTabIndex) { _ in
                    withAnimation(.spring().speed(1.5)) {
                        proxy.scrollTo(currentTabIndex, anchor: .center)
                    }
                }
            }
        }
        .animation(.spring().speed(1.5), value: currentTabIndex)
    }

    @ViewBuilder private func item(title: String, isActive: Bool, namespace: Namespace.ID) -> some View {
        if isActive {
            Text(title)
                .font(.themeSubhead1)
                .foregroundColor(.themeLeah)
                .contentShape(Rectangle())
                .padding(.horizontal, .margin12)
                .frame(height: 44)
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.themeJacob)
                        .frame(height: 4)
                        .offset(x: 0, y: 2)
                        .matchedGeometryEffect(id: "highlightmenuitem", in: namespace)
                }
        } else {
            Text(title)
                .font(.themeSubhead1)
                .foregroundColor(.themeGray)
                .contentShape(Rectangle())
                .padding(.horizontal, .margin12)
                .frame(height: 44)
        }
    }
}

public struct Shimmer: ViewModifier {
    private let animation: Animation
    private let gradient: Gradient
    private let min, max: CGFloat
    @State private var isInitialState = true
    @Environment(\.layoutDirection) private var layoutDirection

    /// Initializes his modifier with a custom animation,
    /// - Parameters:
    ///   - animation: A custom animation. Defaults to ``Shimmer/defaultAnimation``.
    ///   - gradient: A custom gradient. Defaults to ``Shimmer/defaultGradient``.
    ///   - bandSize: The size of the animated mask's "band". Defaults to 0.3 unit points, which corresponds to
    /// 30% of the extent of the gradient.
    public init(
        animation: Animation = Self.defaultAnimation,
        gradient: Gradient = Self.defaultGradient,
        bandSize: CGFloat = 0.3
    ) {
        self.animation = animation
        self.gradient = gradient
        // Calculate unit point dimensions beyond the gradient's edges by the band size
        self.min = 0 - bandSize
        self.max = 1 + bandSize
    }

    /// The default animation effect.
    public static let defaultAnimation = Animation.linear(duration: 1.5).delay(0.25).repeatForever(autoreverses: false)

    // A default gradient for the animated mask.
    public static let defaultGradient = Gradient(colors: [
        .black.opacity(0.3), // translucent
        .black, // opaque
        .black.opacity(0.3), // translucent
    ])

    /*
     Calculating the gradient's animated start and end unit points:
     min,min
        \
         ┌───────┐         ┌───────┐
         │0,0    │ Animate │       │  "forward" gradient
     LTR │       │ ───────►│    1,1│  / // /
         └───────┘         └───────┘
                                    \
                                  max,max
                max,min
                  /
         ┌───────┐         ┌───────┐
         │    1,0│ Animate │       │  "backward" gradient
     RTL │       │ ───────►│0,1    │  \ \\ \
         └───────┘         └───────┘
                          /
                       min,max
     */

    /// The start unit point of our gradient, adjusting for layout direction.
    var startPoint: UnitPoint {
        if layoutDirection == .rightToLeft {
            return isInitialState ? UnitPoint(x: max, y: min) : UnitPoint(x: 0, y: 1)
        } else {
            return isInitialState ? UnitPoint(x: min, y: min) : UnitPoint(x: 1, y: 1)
        }
    }

    /// The end unit point of our gradient, adjusting for layout direction.
    var endPoint: UnitPoint {
        if layoutDirection == .rightToLeft {
            return isInitialState ? UnitPoint(x: 1, y: 0) : UnitPoint(x: min, y: max)
        } else {
            return isInitialState ? UnitPoint(x: 0, y: 0) : UnitPoint(x: max, y: max)
        }
    }

    public func body(content: Content) -> some View {
        content
            .mask(LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint))
            .animation(animation, value: isInitialState)
            .onAppear {
                // Delay the animation until the initial layout is established
                // to prevent animating the appearance of the view
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    isInitialState = false
                }
            }
    }
}

public extension View {
    /// Adds an animated shimmering effect to any view, typically to show that an operation is in progress.
    /// - Parameters:
    ///   - active: Convenience parameter to conditionally enable the effect. Defaults to `true`.
    ///   - animation: A custom animation. Defaults to ``Shimmer/defaultAnimation``.
    ///   - gradient: A custom gradient. Defaults to ``Shimmer/defaultGradient``.
    ///   - bandSize: The size of the animated mask's "band". Defaults to 0.3 unit points, which corresponds to
    /// 20% of the extent of the gradient.
    @ViewBuilder func shimmering(
        active: Bool = true,
        animation: Animation = Shimmer.defaultAnimation,
        gradient: Gradient = Shimmer.defaultGradient,
        bandSize: CGFloat = 0.3
    ) -> some View {
        if active {
            modifier(Shimmer(animation: animation, gradient: gradient, bandSize: bandSize))
        } else {
            self
        }
    }

    /// Adds an animated shimmering effect to any view, typically to show that an operation is in progress.
    /// - Parameters:
    ///   - active: Convenience parameter to conditionally enable the effect. Defaults to `true`.
    ///   - duration: The duration of a shimmer cycle in seconds.
    ///   - bounce: Whether to bounce (reverse) the animation back and forth. Defaults to `false`.
    ///   - delay:A delay in seconds. Defaults to `0.25`.
    @available(*, deprecated, message: "Use shimmering(active:animation:gradient:bandSize:) instead.")
    @ViewBuilder func shimmering(
        active: Bool = true, duration: Double, bounce: Bool = false, delay: Double = 0.25
    ) -> some View {
        shimmering(
            active: active,
            animation: .linear(duration: duration).delay(delay).repeatForever(autoreverses: bounce)
        )
    }
}
