import SwiftUI

struct AutumnParticleView: View {
    @State private var particles: [AutumnParticle] = AutumnParticleView.createParticles()
    @State private var startTime = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                for particle in particles {
                    let age = elapsed - particle.createdAt
                    let cycleAge = age.truncatingRemainder(dividingBy: particle.lifetime)
                    let progress = cycleAge / particle.lifetime

                    let swayX = sin(cycleAge * particle.swaySpeed) * particle.swayAmount
                    let x = particle.startX * size.width + swayX
                    let y = -20 + progress * (size.height + 40)
                    let rotation = Angle.degrees(cycleAge * particle.rotationSpeed)
                    let opacity = progress < 0.1 ? progress / 0.1 : (progress > 0.85 ? (1.0 - progress) / 0.15 : 1.0)

                    context.opacity = opacity * 0.75
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)

                    let leafPath = AutumnParticleView.mapleLeafPath(size: particle.size)
                    context.fill(leafPath, with: .color(particle.color))

                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private static func mapleLeafPath(size: CGFloat) -> Path {
        let s = size / 2
        var path = Path()

        // 중심점에서 시작 (줄기 연결부)
        path.move(to: CGPoint(x: 0, y: s * 0.12))

        // 1. 좌하단 잎
        path.addQuadCurve(to: CGPoint(x: -s * 0.5, y: s * 0.3),
                          control: CGPoint(x: -s * 0.35, y: s * 0.28))
        path.addQuadCurve(to: CGPoint(x: -s * 0.15, y: s * 0.0),
                          control: CGPoint(x: -s * 0.35, y: s * 0.08))

        // 2. 좌측 잎
        path.addQuadCurve(to: CGPoint(x: -s * 0.85, y: -s * 0.08),
                          control: CGPoint(x: -s * 0.6, y: s * 0.05))
        path.addQuadCurve(to: CGPoint(x: -s * 0.22, y: -s * 0.15),
                          control: CGPoint(x: -s * 0.55, y: -s * 0.2))

        // 3. 좌상단 잎
        path.addQuadCurve(to: CGPoint(x: -s * 0.62, y: -s * 0.7),
                          control: CGPoint(x: -s * 0.52, y: -s * 0.38))
        path.addQuadCurve(to: CGPoint(x: -s * 0.1, y: -s * 0.32),
                          control: CGPoint(x: -s * 0.35, y: -s * 0.55))

        // 4. 중앙 잎 (가장 길게)
        path.addQuadCurve(to: CGPoint(x: 0, y: -s),
                          control: CGPoint(x: -s * 0.12, y: -s * 0.7))
        path.addQuadCurve(to: CGPoint(x: s * 0.1, y: -s * 0.32),
                          control: CGPoint(x: s * 0.12, y: -s * 0.7))

        // 5. 우상단 잎
        path.addQuadCurve(to: CGPoint(x: s * 0.62, y: -s * 0.7),
                          control: CGPoint(x: s * 0.35, y: -s * 0.55))
        path.addQuadCurve(to: CGPoint(x: s * 0.22, y: -s * 0.15),
                          control: CGPoint(x: s * 0.52, y: -s * 0.38))

        // 6. 우측 잎
        path.addQuadCurve(to: CGPoint(x: s * 0.85, y: -s * 0.08),
                          control: CGPoint(x: s * 0.55, y: -s * 0.2))
        path.addQuadCurve(to: CGPoint(x: s * 0.15, y: s * 0.0),
                          control: CGPoint(x: s * 0.6, y: s * 0.05))

        // 7. 우하단 잎
        path.addQuadCurve(to: CGPoint(x: s * 0.5, y: s * 0.3),
                          control: CGPoint(x: s * 0.35, y: s * 0.08))
        path.addQuadCurve(to: CGPoint(x: 0, y: s * 0.12),
                          control: CGPoint(x: s * 0.35, y: s * 0.28))

        // 줄기
        path.addLine(to: CGPoint(x: s * 0.025, y: s * 0.55))
        path.addLine(to: CGPoint(x: s * 0.015, y: s))
        path.addLine(to: CGPoint(x: -s * 0.015, y: s))
        path.addLine(to: CGPoint(x: -s * 0.025, y: s * 0.55))

        path.closeSubpath()
        return path
    }

    private static func createParticles() -> [AutumnParticle] {
        let colors: [Color] = [
            Color(red: 0.85, green: 0.45, blue: 0.15),
            Color(red: 0.78, green: 0.30, blue: 0.18),
            Color(red: 0.92, green: 0.65, blue: 0.20),
            Color(red: 0.70, green: 0.35, blue: 0.15)
        ]
        return (0..<12).map { _ in
            AutumnParticle(
                startX: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 10...20),
                lifetime: Double.random(in: 7...14),
                createdAt: -Double.random(in: 0...12),
                swayAmount: CGFloat.random(in: 30...70),
                swaySpeed: Double.random(in: 0.5...1.2),
                rotationSpeed: Double.random(in: 30...80),
                color: colors.randomElement()!
            )
        }
    }
}

private struct AutumnParticle {
    let startX: CGFloat
    let size: CGFloat
    let lifetime: Double
    let createdAt: Double
    let swayAmount: CGFloat
    let swaySpeed: Double
    let rotationSpeed: Double
    let color: Color
}
