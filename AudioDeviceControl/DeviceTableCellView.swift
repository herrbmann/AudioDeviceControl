import SwiftUI

struct DeviceTableCellView: View {

    let icon: NSImage
    let name: String
    let subtitle: String
    let statusColor: NSColor

    var body: some View {
        HStack(spacing: 12) {

            Image(nsImage: icon)
                .resizable()
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14))

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Circle()
                .fill(Color(statusColor))
                .frame(width: 10, height: 10)

            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .padding(.leading, 6)
        }
    }
}
