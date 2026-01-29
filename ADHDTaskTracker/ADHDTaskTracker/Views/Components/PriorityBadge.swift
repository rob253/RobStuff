import SwiftUI

/// Priority badge component showing priority level with color coding
struct PriorityBadge: View {
    let priority: TaskPriority
    var showLabel: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.icon)
                .font(.caption.weight(.semibold))

            if showLabel {
                Text(priority.label)
                    .font(.caption.weight(.medium))
            }
        }
        .foregroundColor(priority.color)
        .padding(.horizontal, showLabel ? 10 : 6)
        .padding(.vertical, 4)
        .background(priority.color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PriorityBadge(priority: .high)
        PriorityBadge(priority: .medium)
        PriorityBadge(priority: .low)

        PriorityBadge(priority: .high, showLabel: true)
        PriorityBadge(priority: .medium, showLabel: true)
        PriorityBadge(priority: .low, showLabel: true)
    }
    .padding()
}
