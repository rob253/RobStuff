//
//  TimeBlockView.swift
//  DailyRoutineBlocks
//

import SwiftUI

struct TimeBlockView: View {
    let block: TimeBlock
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        block.color.opacity(block.isCompleted ? 0.5 : 1.0)
    }

    private var textColor: Color {
        block.color.contrastingTextColor.opacity(block.isCompleted ? 0.7 : 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Icon
                if let iconName = block.icon {
                    Image(systemName: iconName)
                        .font(.system(size: min(height * 0.3, 20)))
                        .foregroundStyle(textColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    // Title
                    Text(block.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(textColor)
                        .strikethrough(block.isCompleted)
                        .lineLimit(1)

                    // Time range (only show if block is tall enough)
                    if height > 50 {
                        Text(block.formattedTimeRange)
                            .font(.caption2)
                            .foregroundStyle(textColor.opacity(0.8))
                    }
                }

                Spacer()

                // Completion indicator
                if block.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(textColor)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: TimelineConstants.blockCornerRadius)
                    .fill(backgroundColor)
                    .shadow(color: .blockShadow, radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(BlockButtonStyle())
        .contextMenu {
            Button(action: onToggleComplete) {
                Label(
                    block.isCompleted ? "Mark Incomplete" : "Mark Complete",
                    systemImage: block.isCompleted ? "circle" : "checkmark.circle"
                )
            }

            Button(action: onTap) {
                Label("Edit", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive, action: {}) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Block Button Style

struct BlockButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Compact Block View (for Week Overview)

struct CompactTimeBlockView: View {
    let block: TimeBlock
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(block.color.opacity(block.isCompleted ? 0.5 : 1.0))
            .frame(height: height)
            .overlay(alignment: .leading) {
                if height > 16 {
                    Text(block.title)
                        .font(.system(size: 8))
                        .foregroundStyle(block.color.contrastingTextColor)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        TimeBlockView(
            block: TimeBlock.sample(
                title: "Morning Workout",
                colorHex: BlockColor.red.hex
            ),
            width: 300,
            height: 60,
            onTap: {},
            onToggleComplete: {}
        )

        TimeBlockView(
            block: {
                let block = TimeBlock.sample(
                    title: "Team Meeting",
                    colorHex: BlockColor.blue.hex
                )
                block.icon = "video"
                return block
            }(),
            width: 300,
            height: 80,
            onTap: {},
            onToggleComplete: {}
        )

        TimeBlockView(
            block: {
                let block = TimeBlock.sample(
                    title: "Completed Task",
                    colorHex: BlockColor.green.hex
                )
                block.isCompleted = true
                return block
            }(),
            width: 300,
            height: 60,
            onTap: {},
            onToggleComplete: {}
        )
    }
    .padding()
}
