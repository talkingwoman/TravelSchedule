import SwiftUI

struct SettingsView: View {
    @Binding var isDarkTheme: Bool
    let onFailure: (TravelFailure) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Toggle("Темная тема", isOn: $isDarkTheme)
                .tint(TravelStyle.blue)
                .frame(minHeight: 60)
            NavigationLink {
                UserAgreementView(onFailure: onFailure)
            } label: {
                HStack {
                    Text("Пользовательское соглашение")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .medium))
                }
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 16) {
                Text("Приложение использует API «Яндекс.Расписания»")
                Text("Версия \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") (beta)")
            }
            .font(.system(size: 12))
            .multilineTextAlignment(.center)
            .padding(.bottom, 24)
        }
        .font(.system(size: 17))
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .background(TravelStyle.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}
