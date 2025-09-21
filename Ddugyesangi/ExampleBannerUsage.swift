import SwiftUI

// MARK: - 각 화면에서 AdService 사용하는 예시

struct ExampleView: View {
    @StateObject private var adService = AdService() // 각 화면에서 새 인스턴스 생성
    
    var body: some View {
        VStack {
            Text("메인 콘텐츠")
                .font(.title)
                .padding()
            
            Spacer()
            
            // 배너 광고 표시
            if adService.isBannerAdLoaded {
                BannerAdView(adService: adService)
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.1))
            } else if let error = adService.adError {
                Text("광고 로드 실패: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("광고 로딩 중...")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .onAppear {
            // 화면이 나타날 때 광고 로드
            adService.loadBannerAd()
        }
    }
}

struct AnotherExampleView: View {
    @StateObject private var adService = AdService() // 각 화면마다 독립적인 인스턴스
    
    var body: some View {
        VStack {
            Text("다른 화면")
                .font(.title)
                .padding()
            
            Spacer()
            
            // 광고 상태에 따른 UI
            Group {
                if adService.isBannerAdLoaded {
                    BannerAdView(adService: adService)
                        .frame(height: 50)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 50)
                        .overlay(
                            Text("광고 준비 중")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }
            }
        }
        .onAppear {
            adService.loadBannerAd()
        }
    }
}

#Preview {
    ExampleView()
}