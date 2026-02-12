import SwiftUI

struct WinterParticleView: View {
    @State private var particles: [WinterParticle] = WinterParticleView.createParticles()
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
                    let y = -10 + progress * (size.height + 20)
                    let opacity = progress < 0.1 ? progress / 0.1 : (progress > 0.9 ? (1.0 - progress) / 0.1 : 1.0)

                    // glow
                    let glowSize = particle.size * 2.5
                    context.opacity = opacity * 0.15
                    let glowRect = CGRect(x: x - glowSize / 2, y: y - glowSize / 2, width: glowSize, height: glowSize)
                    context.fill(Path(ellipseIn: glowRect), with: .color(.white))

                    // snowflake
                    context.opacity = opacity * 0.8
                    let snowRect = CGRect(x: x - particle.size / 2, y: y - particle.size / 2, width: particle.size, height: particle.size)
                    context.fill(Path(ellipseIn: snowRect), with: .color(Color(red: 0.95, green: 0.97, blue: 1.0)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private static func createParticles() -> [WinterParticle] {
        (0..<25).map { _ in
            WinterParticle(
                startX: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 3...8),
                lifetime: Double.random(in: 6...12),
                createdAt: -Double.random(in: 0...10),
                swayAmount: CGFloat.random(in: 10...30),
                swaySpeed: Double.random(in: 0.5...1.5)
            )
        }
    }
}

private struct WinterParticle {
    let startX: CGFloat
    let size: CGFloat
    let lifetime: Double
    let createdAt: Double
    let swayAmount: CGFloat
    let swaySpeed: Double
}
