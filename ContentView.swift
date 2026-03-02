import SwiftUI
import SwiftData

struct Pattern: Identifiable, Codable {
    var id: UUID
    var name: String
    var imageData: Data?
    var category: String
    var tags: [String]
    var notes: String
    var createdAt: Date
    
    init(name: String = "", category: String = "默认", tags: [String] = [], notes: String = "") {
        self.id = UUID()
        self.name = name
        self.imageData = nil
        self.category = category
        self.tags = tags
        self.notes = notes
        self.createdAt = Date()
    }
}

@Model
class PatternItem {
    var id: UUID
    var name: String
    @Attribute(.externalStorage) var imageData: Data?
    var category: String
    var tags: [String]
    var notes: String
    var createdAt: Date
    
    init(pattern: Pattern) {
        self.id = pattern.id
        self.name = pattern.name
        self.imageData = pattern.imageData
        self.category = pattern.category
        self.tags = pattern.tags
        self.notes = pattern.notes
        self.createdAt = pattern.createdAt
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PatternItem.createdAt, order: .reverse) private var patterns: [PatternItem]
    
    @State private var selectedCategory: String = "全部"
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    var categories: [String] {
        var cats = Set(patterns.map { $0.category })
        cats.insert("全部")
        return cats.sorted()
    }
    
    var filteredPatterns: [PatternItem] {
        var result = patterns
        
        if selectedCategory != "全部" {
            result = result.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            result = result.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // 图案网格
                if filteredPatterns.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("还没有图案")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("添加第一个图案", systemImage: "plus")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                            ForEach(filteredPatterns) { pattern in
                                PatternCard(pattern: pattern)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("图案收集册")
            .searchable(text: $searchText, prompt: "搜索图案")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddPatternView(categories: categories)
            }
        }
    }
}

struct PatternCard: View {
    let pattern: PatternItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图片
            if let imageData = pattern.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
            }
            
            // 名称和分类
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.name.isEmpty ? "未命名" : pattern.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(pattern.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct AddPatternView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let categories: [String]
    
    @State private var name = ""
    @State private var category = "默认"
    @State private var notes = ""
    @State private var tagsText = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingImagePicker = true
                    } label: {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        } else {
                            VStack {
                                Image(systemName: "photo.badge.plus")
                                    .font(.largeTitle)
                                Text("添加图片")
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                        }
                    }
                }
                
                Section("资讯") {
                    TextField("名称", text: $name)
                    
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    TextField("笔记", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("标签") {
                    TextField("标签（用逗号分隔）", text: $tagsText)
                }
            }
            .navigationTitle("添加图案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        savePattern()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    func savePattern() {
        let tags = tagsText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        let pattern = Pattern(
            name: name,
            category: category,
            tags: tags,
            notes: notes
        )
        
        if let image = selectedImage {
            pattern.imageData = image.jpegData(compressionQuality: 0.8)
        }
        
        let item = PatternItem(pattern: pattern)
        modelContext.insert(item)
        
        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PatternItem.self, inMemory: true)
}
