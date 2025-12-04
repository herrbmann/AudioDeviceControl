import SwiftUI

struct ReorderTableView: View {
    var items: [AudioDevice]
    let makeDisplayData: (AudioDevice) -> (NSImage, String, String, NSColor)
    let onReorder: ([AudioDevice]) -> Void
    var version: Int = 0
    var isIgnored: ((AudioDevice) -> Bool)? = nil
    var onIgnoreToggle: ((AudioDevice) -> Void)? = nil

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .accessibilityLabel(Text("Zum Sortieren ziehen"))

            List {
                ForEach(items, id: \.identityKey) { device in
                    let (icon, name, subtitle, statusColor) = makeDisplayData(device)
                    HStack(spacing: 12) {
                        DeviceTableCellView(
                            icon: icon,
                            name: name,
                            subtitle: subtitle,
                            statusColor: statusColor
                        )
                        if let isIgnoredCheck = isIgnored, let onIgnoreToggle = onIgnoreToggle {
                            let deviceIsIgnored = isIgnoredCheck(device)
                            Button {
                                onIgnoreToggle(device)
                            } label: {
                                Image(systemName: deviceIsIgnored ? "eye.slash" : "eye")
                                    .help(deviceIsIgnored ? "Ignoriert" : "Sichtbar")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                }
                .onMove(perform: move)
            }
            .scrollContentBackground(.hidden)
            .id(version)
            .background(Color.clear)
            .listStyle(.plain)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var newOrder = items
        newOrder.move(fromOffsets: source, toOffset: destination)
        onReorder(newOrder)
    }
}
