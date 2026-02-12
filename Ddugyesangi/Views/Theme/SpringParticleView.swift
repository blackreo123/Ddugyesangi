import SwiftUI

struct SpringParticleView: View {
    @State private var particles: [SpringParticle] = SpringParticleView.createParticles()
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

                    context.opacity = opacity * 0.7
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)

                    let petalSize = particle.size
                    let petalPath = Path(ellipseIn: CGRect(x: -petalSize / 2, y: -petalSize / 3, width: petalSize, height: petalSize * 0.65))
                    context.fill(petalPath, with: .color(particle.color))

                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private static func createParticles() -> [SpringParticle] {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.75, blue: 0.80),
            Color(red: 1.0, green: 0.85, blue: 0.88),
            Color(red: 0.98, green: 0.70, blue: 0.78),
            Color(red: 1.0, green: 0.80, blue: 0.86)
        ]
        return (0..<15).map { _ in
            SpringParticle(
                startX: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 8...16),
                lifetime: Double.random(in: 6...12),
                createdAt: -Double.random(in: 0...10),
                swayAmount: CGFloat.random(in: 20...50),
                swaySpeed: Double.random(in: 0.8...1.8),
                rotationSpeed: Double.random(in: 20...60),
                color: colors.randomElement()!
            )
        }
    }
}

private struct SpringParticle {
    let startX: CGFloat
    let size: CGFloat
    let lifetime: Double
    let createdAt: Double
    let swayAmount: CGFloat
    let swaySpeed: Double
    let rotationSpeed: Double
    let color: Color
}
