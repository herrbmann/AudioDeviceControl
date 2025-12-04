import SwiftUI

struct DeviceReorderList: View {
    @Binding var devices: [AudioDevice]
    let deviceType: String
    var onIgnore: ((AudioDevice) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Zum Neuordnen ziehen")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 2)
            
            if devices.isEmpty {
                Text("Keine Geräte verfügbar")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            } else {
                List {
                    ForEach(devices, id: \.identityKey) { device in
                        HStack {
                            DeviceRowView(device: device)
                            
                            if let onIgnore = onIgnore {
                                Button {
                                    onIgnore(device)
                                } label: {
                                    Image(systemName: "eye.slash.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14))
                                }
                                .buttonStyle(.borderless)
                                .help("Gerät ignorieren")
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    }
                    .onMove { source, destination in
                        devices.move(fromOffsets: source, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .scrollDisabled(true)
                .frame(height: CGFloat(devices.count) * 50 + 6)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .padding(1)
    }
}

struct DeviceRowView: View {
    let device: AudioDevice
    
    var subtitle: String {
        switch device.state {
        case .offline:
            return "Offline"
        case .active:
            return device.isInput ? "Aktive Eingabe" : "Aktive Ausgabe"
        case .connected:
            return "Verbunden, aber nicht aktiv"
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            DeviceTableCellView(
                icon: device.iconNSImage,
                name: device.name,
                subtitle: subtitle,
                statusColor: device.statusColorNS
            )
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(5)
    }
}

