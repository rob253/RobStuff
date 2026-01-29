import SwiftUI

/// Empty state view with encouraging messaging
/// Designed to be friendly and non-overwhelming for ADHD users
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var color: Color = AppColors.primaryTeal
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(color.opacity(0.8))

            // Title
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Action button (optional)
            if let action = action, let actionLabel = actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(color)
                        .cornerRadius(Constants.buttonCornerRadius)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All done!",
            message: "You've completed all your tasks for today."
        )

        EmptyStateView(
            icon: "magnifyingglass",
            title: "No results",
            message: "Try adjusting your search or filters.",
            color: AppColors.softBlue
        )

        EmptyStateView(
            icon: "plus.circle",
            title: "No tasks yet",
            message: "Tap the button below to add your first task.",
            color: AppColors.sageGreen,
            action: { print("Add task") },
            actionLabel: "Add Task"
        )
    }
}
