import SwiftUI

struct ContentView: View {
    @State private var taps = 0

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("MyApp")
                .font(.largeTitle.bold())

            Text("Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Натиснуто \(taps)") {
                taps += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
