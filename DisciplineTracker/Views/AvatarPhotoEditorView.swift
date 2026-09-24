import SwiftUI
import UIKit

struct AvatarPhotoEditorView: View {
    let image: UIImage
    let onUseOriginal: () -> Void
    let onSaveCrop: (_ zoom: CGFloat, _ offset: CGSize, _ viewport: CGFloat) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var zoom: CGFloat = 1
    @State private var settledZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var settledOffset: CGSize = .zero

    private let viewport: CGFloat = 300

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Move and zoom the photo inside the circle.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                cropPreview

                VStack(spacing: 12) {
                    Button {
                        onSaveCrop(zoom, offset, viewport)
                        dismiss()
                    } label: {
                        Label("Save crop", systemImage: "crop")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        onUseOriginal()
                        dismiss()
                    } label: {
                        Label("Keep entire photo", systemImage: "rectangle.inset.filled")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 0)
            }
            .padding(.top, 20)
            .navigationTitle("Edit profile photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .tint(AppTheme.accent)
    }

    private var cropPreview: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: viewport, height: viewport)
            .scaleEffect(zoom)
            .offset(offset)
            .frame(width: viewport, height: viewport)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(AppTheme.accent, lineWidth: 3)
                Circle()
                    .stroke(.white.opacity(0.35), lineWidth: 1)
                    .padding(10)
            }
            .shadow(color: AppTheme.accent.opacity(0.22), radius: 22)
            .contentShape(Circle())
            .gesture(dragGesture)
            .simultaneousGesture(zoomGesture)
            .accessibilityLabel("Photo crop preview")
            .accessibilityHint("Drag to reposition and pinch to zoom")
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: settledOffset.width + value.translation.width,
                    height: settledOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                offset = clampedOffset(offset, zoom: zoom)
                settledOffset = offset
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoom = min(max(settledZoom * value, 1), 4)
                offset = clampedOffset(offset, zoom: zoom)
            }
            .onEnded { _ in
                settledZoom = zoom
                offset = clampedOffset(offset, zoom: zoom)
                settledOffset = offset
            }
    }

    private func clampedOffset(_ proposed: CGSize, zoom: CGFloat) -> CGSize {
        let imageRatio = image.size.width / image.size.height
        let baseSize: CGSize
        if imageRatio > 1 {
            baseSize = CGSize(width: viewport * imageRatio, height: viewport)
        } else {
            baseSize = CGSize(width: viewport, height: viewport / imageRatio)
        }

        let horizontalLimit = max((baseSize.width * zoom - viewport) / 2, 0)
        let verticalLimit = max((baseSize.height * zoom - viewport) / 2, 0)
        return CGSize(
            width: min(max(proposed.width, -horizontalLimit), horizontalLimit),
            height: min(max(proposed.height, -verticalLimit), verticalLimit)
        )
    }
}
