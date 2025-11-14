import SwiftUI

struct LogoView: View {
    var maxWidth: CGFloat = 200

    var body: some View {
        Image("AppLogo")          // AppLogo.png / @2x / @3x im Asset Catalog
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth)
            .accessibilityLabel(Text("App Logo"))
    }
}

#Preview {
    LogoView()
        .padding()
        .background(
            Color(NSColor.windowBackgroundColor)  // macOS-konform
        )
}
