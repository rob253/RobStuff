import SwiftUI

/// Tag badge component for displaying tags with colors
struct TagBadge: View {
    let tag: TagEntity
    var showLabel: Bool = true
    var size: TagBadgeSize = .small

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tag.color)
                .frame(width: dotSize, height: dotSize)

            if showLabel {
                Text(tag.name ?? "Tag")
                    .font(fontSize)
                    .lineLimit(1)
            }
        }
        .foregroundColor(tag.color)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(tag.color.opacity(0.15))
        .cornerRadius(cornerRadius)
    }

    // MARK: - Size Properties

    private var dotSize: CGFloat {
        switch size {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }

    private var fontSize: Font {
        switch size {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return 4
        case .medium: return 5
        case .large: return 6
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }
}

// MARK: - Tag Badge Size

enum TagBadgeSize {
    case small
    case medium
    case large
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        let context = PersistenceController.preview.container.viewContext
        let tag = TagEntity(context: context)
        tag.name = "Work"
        tag.colorHex = "#6B9AC4"

        TagBadge(tag: tag, size: .small)
        TagBadge(tag: tag, size: .medium)
        TagBadge(tag: tag, size: .large)
        TagBadge(tag: tag, showLabel: false)
    }
    .padding()
}
