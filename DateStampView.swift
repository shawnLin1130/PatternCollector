import SwiftUI
import SwiftData

// MARK: - 日期印章选择Sheet
struct DateStampPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void
    
    @State private var selectedFormat: DateStampFormat = .ymd
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 预览
                VStack(spacing: 8) {
                    Text("预览效果")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(DateStamp.formatDate(type: selectedFormat.rawValue))
                        .font(.system(.title2, design: .rounded, weight: .medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(CuteColors.pink.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 20)
                
                // 格式选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择日期格式")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(DateStampFormat.allCases, id: \.self) { format in
                        Button {
                            selectedFormat = format
                        } label: {
                            HStack {
                                Text(format.displayName)
                                    .font(.system(.body, design: .rounded))
                                
                                Spacer()
                                
                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(CuteColors.pink)
                                }
                            }
                            .padding()
                            .background(selectedFormat == format ? CuteColors.pink.opacity(0.1) : Color.gray.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 添加按钮
                Button {
                    onSelect(selectedFormat.rawValue)
                    dismiss()
                } label: {
                    Text("添加日期印章 ✨")
                        .font(.headline)
                        .fontDesign(.rounded)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [CuteColors.pink, Color(hex: "#FF69B4")!],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .pink.opacity(0.4), radius: 8)
                }
                .padding()
            }
            .navigationTitle("添加日期印章")
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

// MARK: - 日期印章组件（可拖拽）
struct DraggableDateStampView: View {
    @Bindable var dateStamp: DateStamp
    let isSelected: Bool
    let onTap: () -> Void
    let onUpdate: (DateStamp) -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        Group {
            Text(dateStamp.dateString)
                .font(.system(size: dateStamp.fontSize, design: .rounded))
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: dateStamp.page?.backgroundColor ?? "#FFF8F0") ?? Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? CuteColors.pink : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
                .rotationEffect(.degrees(dateStamp.rotation))
                .shadow(color: isDragging ? .pink.opacity(0.3) : .black.opacity(0.1), radius: isDragging ? 8 : 2)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            offset = CGSize(width: value.translation.width, height: value.translation.height)
                        }
                        .onEnded { value in
                            isDragging = false
                            dateStamp.x += value.translation.width
                            dateStamp.y += value.translation.height
                            offset = .zero
                            onUpdate(dateStamp)
                        }
                )
                .onTapGesture {
                    onTap()
                }
        }
    }
}

// MARK: - 日期印章编辑器Sheet
struct DateStampEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var dateStamp: DateStamp
    let onDismiss: () -> Void
    
    @State private var dateString: String = ""
    @State private var fontSize: Double = 16
    @State private var rotation: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("预览") {
                    HStack {
                        Spacer()
                        Text(dateString.isEmpty ? dateStamp.dateString : dateString)
                            .font(.system(size: fontSize, design: .rounded))
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(CuteColors.pink.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .rotationEffect(.degrees(rotation))
                        Spacer()
                    }
                    .frame(height: 60)
                }
                
                Section("日期文本") {
                    TextField("自定义日期文字", text: $dateString)
                        .fontDesign(.rounded)
                }
                
                Section("字体大小") {
                    VStack {
                        Slider(value: $fontSize, in: 10...32, step: 1) {
                            Text("字体大小")
                        }
                        Text("\(Int(fontSize))pt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("旋转") {
                    VStack {
                        Slider(value: $rotation, in: -45...45, step: 5) {
                            Text("旋转角度")
                        }
                        Text("\(Int(rotation))°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteStamp()
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除日期印章")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑日期印章")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onDismiss()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .onAppear {
                dateString = dateStamp.dateString
                fontSize = dateStamp.fontSize
                rotation = dateStamp.rotation
            }
        }
    }
    
    private func saveChanges() {
        if !dateString.isEmpty {
            dateStamp.dateString = dateString
        }
        dateStamp.fontSize = fontSize
        dateStamp.rotation = rotation
    }
    
    private func deleteStamp() {
        modelContext.delete(dateStamp)
    }
}
