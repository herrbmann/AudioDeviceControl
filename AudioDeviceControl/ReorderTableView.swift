import SwiftUI

struct ReorderTableView: View {
    var items: [AudioDevice]
    let makeDisplayData: (AudioDevice) -> (NSImage, String, String, NSColor)
    let onReorder: ([AudioDevice]) -> Void
    var version: Int = 0

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .accessibilityLabel(Text("Drag to reorder"))

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
                        let isIgnored = PriorityStore.shared.loadIgnoredUIDs().contains(device.persistentUID)
                        Button {
                            AudioState.shared.ignoreDevice(device)
                        } label: {
                            Image(systemName: isIgnored ? "eye.slash" : "eye")
                                .help(isIgnored ? "Ignored" : "Visible")
                        }
                        .buttonStyle(.borderless)
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
