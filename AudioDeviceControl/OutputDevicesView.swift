import SwiftUI

struct OutputDevicesView: View {

    @ObservedObject private var state = AudioState.shared

    var body: some View {

        ReorderTableView(
            items: state.outputDevices,
            makeDisplayData: { device in

                let subtitle: String
                if !device.isConnected {
                    subtitle = "Offline"
                } else if device.id == state.defaultOutputID {
                    subtitle = "Active Output"
                } else {
                    subtitle = "Connected"
                }

                let color: NSColor =
                    device.id == state.defaultOutputID
                    ? .systemGreen
                    : (device.isConnected ? .systemBlue : .systemGray)

                return (device.iconNSImage, device.name, subtitle, color)
            },
            onReorder: { newList in
                AudioState.shared.updateOutputOrder(newList)
            }
        )
        .frame(height: 340)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}
