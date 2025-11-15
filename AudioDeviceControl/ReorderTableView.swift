import SwiftUI

struct ReorderTableView: View {
    var items: [AudioDevice]
    let makeDisplayData: (AudioDevice) -> (NSImage, String, String, NSColor)
    let onReorder: ([AudioDevice]) -> Void

    @State private var localItems: [AudioDevice] = []

    init(
        items: [AudioDevice],
        makeDisplayData: @escaping (AudioDevice) -> (NSImage, String, String, NSColor),
        onReorder: @escaping ([AudioDevice]) -> Void
    ) {
        self.items = items
        self.makeDisplayData = makeDisplayData
        self.onReorder = onReorder
        self._localItems = State(initialValue: items)
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .accessibilityLabel(Text("Drag to reorder"))

            List {
                ForEach(localItems) { device in
                    let (icon, name, subtitle, statusColor) = makeDisplayData(device)
                    DeviceTableCellView(
                        icon: icon,
                        name: name,
                        subtitle: subtitle,
                        statusColor: statusColor
                    )
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                }
                .onMove(perform: move)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listStyle(.plain)
            .onChange(of: items) { _, newValue in
                localItems = newValue
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        localItems.move(fromOffsets: source, toOffset: destination)
        onReorder(localItems)
    }
}
