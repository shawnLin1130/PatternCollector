import SwiftUI
import SwiftData

// MARK: - 心情贴纸选择视图
struct MoodStickersPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String, String) -> Void  // (moodType, emoji)
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题
                    Text("今天的心情 💭")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // 心情网格
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            Button {
                                onSelect(mood.rawValue, mood.emoji)
                                dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    Text(mood.emoji)
                                        .font(.system(size: 48))
                                    
                                    Text(mood.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .frame(width: 70, height: 90)
                                .background(Color(hex: "#F8D7DA").opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(CuteColors.pink.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 更多表情
                    VStack(alignment: .leading, spacing: 12) {
                        Text("更多表情")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(["😍", "🥺", "🤔", "😎", "😇", "😈", "🙈", "🥳", "😭", "🤗"], id: \.self) { emoji in
                                Button {
                                    onSelect("custom", emoji)
                                    dismiss()
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 36))
                                        .frame(width: 60, height: 60)
                                        .background(Color.pink.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("选择心情贴纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 可拖拽心情贴纸视图
struct DraggableMoodStickerView: View {
    @Bindable var moodSticker: MoodSticker
    let isSelected: Bool
    let onTap: () -> Void
    let onUpdate: (MoodSticker) -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Double = 0
    @State private var lastScale: CGFloat = 1.0
    @State private var lastRotation: Double = 0
    
    var body: some View {
        Group {
            Text(moodSticker.emoji)
                .font(.system(size: 48 * moodSticker.scale))
                .rotationEffect(.degrees(moodSticker.rotation + currentRotation))
                .scaleEffect(currentScale)
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? CuteColors.pink : .clear, lineWidth: 3)
                )
                .shadow(color: isSelected ? .pink.opacity(0.4) : .black.opacity(0.15), radius: isSelected ? 10 : 4)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(width: value.translation.width, height: value.translation.height)
                        }
                        .onEnded { value in
                            moodSticker.x += value.translation.width
                            moodSticker.y += value.translation.height
                            offset = .zero
                            onUpdate(moodSticker)
                        }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { scale in
                            currentScale = lastScale * scale
                        }
                        .onEnded { scale in
                            let newScale = moodSticker.scale * lastScale * scale
                            moodSticker.scale = max(0.5, min(newScale, 2.5))
                            lastScale = 1.0
                            currentScale = 1.0
                            onUpdate(moodSticker)
                        }
                )
                .simultaneousGesture(
                    RotationGesture()
                        .onChanged { angle in
                            currentRotation = lastRotation + angle.degrees
                        }
                        .onEnded { angle in
                            moodSticker.rotation += lastRotation + angle.degrees
                            lastRotation = 0
                            currentRotation = 0
                            onUpdate(moodSticker)
                        }
                )
                .onTapGesture {
                    onTap()
                }
        }
    }
}

// MARK: - 心情贴纸编辑器
struct MoodStickerEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var moodSticker: MoodSticker
    let onDismiss: () -> Void
    
    @State private var scale: Double = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 预览
                Text(moodSticker.emoji)
                    .font(.system(size: 80 * scale))
                    .rotationEffect(.degrees(rotation))
                    .padding()
                
                Form {
                    Section("调整") {
                        VStack {
                            Slider(value: $scale, in: 0.5...2.5, step: 0.1) {
                                Text("大小")
                            }
                            Text("\(String(format: "%.1f", scale))x")
                                .font(.caption)
                        }
                        
                        VStack {
                            Slider(value: $rotation, in: -360...360, step: 15) {
                                Text("旋转")
                            }
                            Text("\(Int(rotation))°")
                                .font(.caption)
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            modelContext.delete(moodSticker)
                            onDismiss()
                            dismiss()
                        } label: {
                            Label("删除心情贴纸", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("编辑心情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        moodSticker.scale = scale
                        moodSticker.rotation = rotation
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .onAppear {
                scale = moodSticker.scale
                rotation = moodSticker.rotation
            }
        }
    }
}
