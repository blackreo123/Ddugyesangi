import SwiftUI

struct SummerParticleView: View {
    @State private var particles: [SummerParticle] = SummerParticleView.createParticles()
    @State private var startTime = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                for particle in particles {
                    let age = elapsed - particle.createdAt
                    let cycleAge = age.truncatingRemainder(dividingBy: particle.lifetime)

                    let driftX = sin(cycleAge * particle.driftSpeedX) * particle.driftAmountX
                    let driftY = cos(cycleAge * particle.driftSpeedY) * particle.driftAmountY
                    let x = particle.baseX * size.width + driftX
                    let y = particle.baseY * size.height + driftY

                    let flicker = (sin(cycleAge * particle.flickerSpeed) + 1.0) / 2.0
                    let opacity = 0.3 + flicker * 0.7

                    // glow
                    let glowSize = particle.size * 3.0
                    context.opacity = opacity * 0.2
                    let glowRect = CGRect(x: x - glowSize / 2, y: y - glowSize / 2, width: glowSize, height: glowSize)
                    context.fill(Path(ellipseIn: glowRect), with: .color(particle.color))

                    // core
                    context.opacity = opacity * 0.9
                    let coreRect = CGRect(x: x - particle.size / 2, y: y - particle.size / 2, width: particle.size, height: particle.size)
                    context.fill(Path(ellipseIn: coreRect), with: .color(Color(red: 1.0, green: 1.0, blue: 0.85)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private static func createParticles() -> [SummerParticle] {
        (0..<20).map { _ in
            SummerParticle(
                baseX: CGFloat.random(in: 0.05...0.95),
                baseY: CGFloat.random(in: 0.1...0.9),
                size: CGFloat.random(in: 3...6),
                lifetime: Double.random(in: 4...8),
                createdAt: -Double.random(in: 0...6),
                driftAmountX: CGFloat.random(in: 15...40),
                driftAmountY: CGFloat.random(in: 10...30),
                driftSpeedX: Double.random(in: 0.3...0.8),
                driftSpeedY: Double.random(in: 0.2...0.6),
                flickerSpeed: Double.random(in: 2.0...5.0),
                color: Color(red: 1.0, green: 0.95, blue: 0.4).opacity(0.8)
            )
        }
    }
}

private struct SummerParticle {
    let baseX: CGFloat
    let baseY: CGFloat
    let size: CGFloat
    let lifetime: Double
    let createdAt: Double
    let driftAmountX: CGFloat
    let driftAmountY: CGFloat
    let driftSpeedX: Double
    let driftSpeedY: Double
    let flickerSpeed: Double
    let color: Color
}
