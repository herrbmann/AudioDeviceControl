import SwiftUI

struct OutputDevicesView: View {

    @ObservedObject private var state = AudioState.shared

    var body: some View {

        ReorderTableView(
            items: state.outputDevices,
            makeDisplayData: { device in

                let subtitle: String
                switch device.state {
                case .offline:
                    subtitle = "Offline"
                case .active:
                    subtitle = "Active Output"
                case .connected:
                    subtitle = "Connected but not active"
                }

                let color: NSColor = device.statusColorNS

                return (device.iconNSImage, device.name, subtitle, color)
            },
            onReorder: { newList in
                AudioState.shared.updateOutputOrder(newList)
            },
            version: state.listVersion
        )
        .frame(height: 408)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}
