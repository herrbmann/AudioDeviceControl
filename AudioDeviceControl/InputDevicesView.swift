import SwiftUI

struct InputDevicesView: View {

    @ObservedObject private var state = AudioState.shared

    var body: some View {

        ReorderTableView(
            items: state.inputDevices,
            makeDisplayData: { device in

                let subtitle: String
                switch device.state {
                case .offline:
                    subtitle = "Offline"
                case .active:
                    subtitle = "Active Input"
                case .connected:
                    subtitle = "Connected but not active"
                }

                let color: NSColor = device.statusColorNS

                return (device.iconNSImage, device.name, subtitle, color)
            },
            onReorder: { newList in
                AudioState.shared.updateInputOrder(newList)
            },
            version: state.listVersion
        )
        .frame(height: 408)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}
