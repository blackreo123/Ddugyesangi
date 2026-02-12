import SwiftUI

struct SeasonalBackgroundView: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            if let colors = theme.gradientColors {
                LinearGradient(
                    colors: colors,
                    startPoint: theme.gradientStartPoint ?? .top,
                    endPoint: theme.gradientEndPoint ?? .bottom
                )
            }

            switch theme.type {
            case .spring:
                SpringParticleView()
            case .summer:
                SummerParticleView()
            case .autumn:
                AutumnParticleView()
            case .winter:
                WinterParticleView()
            default:
                EmptyView()
            }
        }
    }
}
