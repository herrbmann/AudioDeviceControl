import SwiftUI

struct DeviceReorderList: View {
    @Binding var devices: [AudioDevice]
    let deviceType: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Zum Neuordnen ziehen")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            if devices.isEmpty {
                Text("Keine Geräte verfügbar")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                List {
                    ForEach(devices, id: \.identityKey) { device in
                        DeviceRowView(device: device)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    }
                    .onMove { source, destination in
                        devices.move(fromOffsets: source, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .scrollDisabled(true)
                .frame(height: CGFloat(devices.count) * 60 + 10)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(2)
    }
}

struct DeviceRowView: View {
    let device: AudioDevice
    
    var subtitle: String {
        switch device.state {
        case .offline:
            return "Offline"
        case .active:
            return device.isInput ? "Active Input" : "Active Output"
        case .connected:
            return "Connected but not active"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            DeviceTableCellView(
                icon: device.iconNSImage,
                name: device.name,
                subtitle: subtitle,
                statusColor: device.statusColorNS
            )
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
}

