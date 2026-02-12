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

                    let leafW = particle.size
                    let leafH = particle.size * 0.6
                    let leafPath = Path(ellipseIn: CGRect(x: -leafW / 2, y: -leafH / 2, width: leafW, height: leafH))
                    context.fill(leafPath, with: .color(particle.color))

                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .allowsHitTesting(false)
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
