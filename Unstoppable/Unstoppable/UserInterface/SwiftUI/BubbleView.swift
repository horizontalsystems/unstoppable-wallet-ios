import SwiftUI

struct BubbleView<Content: View>: View {
    let content: Content
    let tailPosition: BubbleShape.TailPosition
    let strokeColor: Color?
    let fillColor: Color?
    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat
    let tailOffset: CGFloat
    let strokeWidth: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let minHeight: CGFloat?

    init(
        tailPosition: BubbleShape.TailPosition = .bottom,
        strokeColor: Color? = nil,
        fillColor: Color? = nil,
        cornerRadius: CGFloat = 16,
        tailWidth: CGFloat = 16,
        tailHeight: CGFloat = 8,
        tailOffset: CGFloat = 48,
        strokeWidth: CGFloat = 1,
        horizontalPadding: CGFloat = 24,
        verticalPadding: CGFloat = 16,
        minHeight: CGFloat = 90,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.tailPosition = tailPosition
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.cornerRadius = cornerRadius
        self.tailWidth = tailWidth
        self.tailHeight = tailHeight
        self.tailOffset = tailOffset
        self.strokeWidth = strokeWidth
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.minHeight = minHeight
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .padding(tailPosition == .top ? .top : .bottom, tailHeight) // Extra padding for tail
            .frame(minHeight: minHeight, alignment: .top)
            .background(
                Group {
                    if let fillColor {
                        BubbleShape(
                            cornerRadius: cornerRadius,
                            tailWidth: tailWidth,
                            tailHeight: tailHeight,
                            tailOffset: tailOffset,
                            tailPosition: tailPosition,
                            strokeWidth: strokeColor != nil ? strokeWidth : 0
                        )
                        .fill(fillColor)
                    }
                }
            )
            .overlay(
                Group {
                    if let strokeColor {
                        BubbleShape(
                            cornerRadius: cornerRadius,
                            tailWidth: tailWidth,
                            tailHeight: tailHeight,
                            tailOffset: tailOffset,
                            tailPosition: tailPosition,
                            strokeWidth: strokeWidth
                        )
                        .stroke(strokeColor, lineWidth: strokeWidth)
                    }
                }
            )
    }
}

struct BubbleShape: Shape {
    enum TailPosition {
        case top
        case bottom
    }

    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat
    let tailOffset: CGFloat
    let tailPosition: TailPosition
    let strokeWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Inset by half stroke width to keep stroke inside bounds
        let inset = strokeWidth / 2
        let insetRect = rect.insetBy(dx: inset, dy: inset)

        // Adjust rect to account for tail
        let bubbleRect: CGRect
        if tailPosition == .bottom {
            bubbleRect = CGRect(
                x: insetRect.minX,
                y: insetRect.minY,
                width: insetRect.width,
                height: insetRect.height - tailHeight
            )
        } else {
            bubbleRect = CGRect(
                x: insetRect.minX,
                y: insetRect.minY + tailHeight,
                width: insetRect.width,
                height: insetRect.height - tailHeight
            )
        }

        // Calculate tail positions
        let tailLeftEdge = tailOffset
        let tailCenter = tailOffset + tailWidth / 2
        let tailRightEdge = tailOffset + tailWidth

        if tailPosition == .bottom {
            // Start from top-left corner
            path.move(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY))

            // Top edge
            path.addLine(to: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY))
            path.addArc(center: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY + cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(0),
                        clockwise: false)

            // Right edge
            path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - cornerRadius))
            path.addArc(center: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.maxY - cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(0),
                        endAngle: .degrees(90),
                        clockwise: false)

            // Bottom edge (right side of tail)
            path.addLine(to: CGPoint(x: tailRightEdge, y: bubbleRect.maxY))

            // Tail triangle
            path.addLine(to: CGPoint(x: tailCenter, y: bubbleRect.maxY + tailHeight))
            path.addLine(to: CGPoint(x: tailLeftEdge, y: bubbleRect.maxY))

            // Bottom edge (left side of tail)
            path.addLine(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY))
            path.addArc(center: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY - cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(90),
                        endAngle: .degrees(180),
                        clockwise: false)

            // Left edge
            path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + cornerRadius))
            path.addArc(center: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY + cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(270),
                        clockwise: false)
        } else {
            // Start from top-left, after the tail
            path.move(to: CGPoint(x: tailLeftEdge, y: bubbleRect.minY))

            // Tail triangle
            path.addLine(to: CGPoint(x: tailCenter, y: bubbleRect.minY - tailHeight))
            path.addLine(to: CGPoint(x: tailRightEdge, y: bubbleRect.minY))

            // Top edge (right side of tail)
            path.addLine(to: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY))
            path.addArc(center: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.minY + cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(0),
                        clockwise: false)

            // Right edge
            path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - cornerRadius))
            path.addArc(center: CGPoint(x: bubbleRect.maxX - cornerRadius, y: bubbleRect.maxY - cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(0),
                        endAngle: .degrees(90),
                        clockwise: false)

            // Bottom edge
            path.addLine(to: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY))
            path.addArc(center: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.maxY - cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(90),
                        endAngle: .degrees(180),
                        clockwise: false)

            // Left edge
            path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + cornerRadius))
            path.addArc(center: CGPoint(x: bubbleRect.minX + cornerRadius, y: bubbleRect.minY + cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(270),
                        clockwise: false)

            // Top edge (left side of tail)
            path.addLine(to: CGPoint(x: tailLeftEdge, y: bubbleRect.minY))
        }

        path.closeSubpath()
        return path
    }
}
