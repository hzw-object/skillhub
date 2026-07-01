import SwiftUI

struct SkillRowView: View {
    let entry: SkillEntry
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.name).font(.body).bold()
                if let v = entry.version {
                    Text(v)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(.quaternary, in: .capsule)
                }
            }
            if !entry.description.isEmpty {
                Text(entry.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}
