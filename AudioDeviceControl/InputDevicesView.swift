import SwiftUI

struct InputDevicesView: View {

    @ObservedObject private var state = AudioState.shared

    var body: some View {

        ReorderTableView(
            items: state.inputDevices,
            makeDisplayData: { device in

                let subtitle: String
                if !device.isConnected {
                    subtitle = "Offline"
                } else if device.id == state.defaultInputID {
                    subtitle = "Active Input"
                } else {
                    subtitle = "Connected"
                }

                let color: NSColor =
                    device.id == state.defaultInputID
                    ? .systemGreen
                    : (device.isConnected ? .systemBlue : .systemGray)

                return (device.iconNSImage, device.name, subtitle, color)
            },
            onReorder: { newList in
                AudioState.shared.updateInputOrder(newList)
            }
        )
        .frame(height: 408)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}
