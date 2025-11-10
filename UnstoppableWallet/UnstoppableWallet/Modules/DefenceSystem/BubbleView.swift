import SwiftUI

struct BubbleView<Content: View>: View {
    let direction: DefenseMessageModule.Direction
    let color: Color
    let content: () -> Content
    
    init(direction: DefenseMessageModule.Direction, color: Color, @ViewBuilder content: @escaping () -> Content) {
        self.direction = direction
        self.color = color
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: -1) {
            if direction == .top {
                tail(rotated: false)
            }
            
            content()
                .padding(.vertical, .margin16)
                .padding(.horizontal, .margin24)
                .frame(maxWidth: .infinity, minHeight: .minHeightBubble)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius16)
                        .fill(color)
//                        .animation(.easeInOut(duration: DefenseMessageModule.animationTime), value: color)
                )
            
            if direction == .bottom {
                tail(rotated: true)
            }
        }
    }
    
    @ViewBuilder
    private func tail(rotated: Bool) -> some View {
        Triangle()
            .fill(color)
            .frame(width: 16, height: 8)
            .rotationEffect(rotated ? .degrees(180) : .zero)
            .padding(.leading, .margin48)
            .animation(.easeInOut(duration: DefenseMessageModule.animationTime), value: color)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}
