import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        VStack {
            // 메인 콘텐츠
            VStack(spacing: 20) {
                Text("Ddugyesangi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("간단한 광고 앱")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // 광고 버튼들
                VStack(spacing: 15) {
                    Button("전면 광고 보기") {
                        viewModel.showInterstitialAd()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("보상형 광고 보기") {
                        viewModel.showRewardedAd()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            
            Spacer()
            
            // 배너 광고 영역
            BannerAdView()
                .frame(height: 50)
        }
        .onAppear {
            viewModel.loadAds()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 