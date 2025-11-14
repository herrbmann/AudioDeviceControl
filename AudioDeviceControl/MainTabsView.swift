import SwiftUI
import AppKit

struct MainTabsView: View {

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 12) {

            // ✳️ App Title ganz oben
            Text("AudioDeviceControl")
                .font(.title3)
                .bold()
                .padding(.top, 8)

            Divider()
                .padding(.horizontal, 12)

            // ✳️ Tabs darunter
            Picker("", selection: $selectedTab) {
                Text("Output").tag(0)
                Text("Input").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            // ✳️ Content
            Group {
                if selectedTab == 0 {
                    OutputDevicesView()
                } else {
                    InputDevicesView()
                }
            }
            .padding(.top, 4)

            // ✳️ Tutorial / Short Description
            VStack(spacing: 8) {

                Text("Drag & drop to set your preferred priority.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                Text("AudioDeviceControl automatically selects the highest available device.")
                    .font(.callout)
                    .foregroundColor(.secondary)

                // Farbcode-Erklärung – mit farbigen Kreisen
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text("●")
                            .foregroundColor(.green)
                        Text("Green = Active device")
                    }
                    HStack(spacing: 6) {
                        Text("●")
                            .foregroundColor(.blue)
                        Text("Blue = Connected but not active")
                    }
                    HStack(spacing: 6) {
                        Text("●")
                            .foregroundColor(.gray)
                        Text("Gray = Offline or not available")
                    }
                }
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.top, 4)

                // Welche Geräte angezeigt werden
                Text("Only real input/output audio devices are shown — virtual routing devices are hidden to keep this list clean.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.top, 6)

            // ✳️ Feedback-Bereich
            Divider()
                .padding(.horizontal, 18)
                .padding(.top, 6)

            VStack(spacing: 4) {
                Text("Got feedback or an idea for a great new feature?")
                    .font(.callout)
                    .foregroundColor(.secondary)

                if let url = URL(string: "mailto:audiocontrol@techbude.com") {
                    Link("Send us an email at audiocontrol@techbude.com", destination: url)
                        .font(.callout)
                } else {
                    Text("Send us an email at audiocontrol@techbude.com")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)

            // ✳️ Footer-Credit
            Divider()
                .padding(.horizontal, 18)
                .padding(.top, 6)

            Text("made without a clue by techbude")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 8)

            // ✳️ Close Button unten
            Button("Close") {
                NSApplication.shared.keyWindow?.close()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
