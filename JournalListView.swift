import SwiftUI
import SwiftData

// 手帐本列表视图
struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalBook.createdAt, order: .reverse) private var books: [JournalBook]
    
    @State private var showingCreateSheet = false
    @State private var newBookName = ""
    @State private var newBookColor = "#FFB6C1" // 默认粉色
    
    // 可爱的封面颜色选项
    let coverColors = [
        "#FFB6C1", // 浅粉色
        "#FF69B4", // 热烈粉
        "#87CEEB", // 天蓝色
        "#98FB98", // 薄荷绿
        "#DDA0DD", // 梅红色
        "#FFA500", // 橙色
        "#E6E6FA", // 薰衣草
        "#F0E68C"  // 卡其色
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [Color(hex: "#FFF0F5").opacity(0.6), Color(hex: "#E0F2FE").opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if books.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 70))
                            .foregroundColor(CuteColors.pink.opacity(0.7))
                            .symbolEffect(.bounce, value: books.isEmpty)
                        
                        Text("还没有手帐本呢～💕")
                            .font(.system(.title2, design: .rounded, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("创建第一本手帐～✨", systemImage: "plus.circle.fill")
                                .fontDesign(.rounded)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [CuteColors.pink, Color(hex: "#FF69B4")!],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .pink.opacity(0.4), radius: 8)
                        }
                    }
                } else {
                    // 手帐本网格
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 20) {
                            ForEach(books) { book in
                                NavigationLink {
                                    JournalDetailView(book: book)
                                } label: {
                                    JournalBookCover(book: book)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteBook(book)
                                    } label: {
                                        Label("删除手帐本", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("我的手帐本💕")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(CuteColors.pink)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateJournalSheet(
                    bookName: $newBookName,
                    bookColor: $newBookColor,
                    coverColors: coverColors,
                    onCreate: createBook,
                    onCancel: {
                        newBookName = ""
                        newBookColor = "#FFB6C1"
                    }
                )
            }
        }
    }
    
    private func createBook() {
        let book = JournalBook(name: newBookName.isEmpty ? "新手帐本" : newBookName, coverColor: newBookColor)
        // 自动创建第一页
        let firstPage = JournalPage(pageNumber: 1)
        book.pages.append(firstPage)
        
        modelContext.insert(book)
        
        newBookName = ""
        newBookColor = "#FFB6C1"
    }
    
    private func deleteBook(_ book: JournalBook) {
        modelContext.delete(book)
    }
}

// 手帐本封面组件
struct JournalBookCover: View {
    let book: JournalBook
    
    var body: some View {
        VStack(spacing: 0) {
            // 书本封面
            ZStack {
                if let imageData = book.coverImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    // 纯色封面
                    LinearGradient(
                        colors: [
                            Color(hex: book.coverColor) ?? CuteColors.pink,
                            (Color(hex: book.coverColor) ?? CuteColors.pink).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                
                // 书本厚度效果
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 8)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
            
            // 书本信息
            VStack(spacing: 4) {
                Text(book.name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .lineLimit(1)
                
                Text("\(book.pages.count) 页")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(8)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// 创建手帐本Sheet
struct CreateJournalSheet: View {
    @Binding var bookName: String
    @Binding var bookColor: String
    let coverColors: [String]
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 预览
                VStack(spacing: 8) {
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: bookColor) ?? CuteColors.pink, Color(hex: bookColor)?.opacity(0.7) ?? CuteColors.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 100, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                        
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(bookName.isEmpty ? "新手帐本" : bookName)
                        .font(.system(.headline, design: .rounded))
                }
                .padding(.top, 20)
                
                // 名字输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("手帐本名字")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("给我的手帐本起个名字～", text: $bookName)
                        .textFieldStyle(.roundedBorder)
                        .fontDesign(.rounded)
                }
                .padding(.horizontal)
                
                // 颜色选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("封面颜色")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(coverColors, id: \.self) { color in
                            Button {
                                bookColor = color
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color) ?? CuteColors.pink)
                                        .frame(width: 44, height: 44)
                                    
                                    if bookColor == color {
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 3)
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // 按钮
                Button {
                    onCreate()
                    dismiss()
                } label: {
                    Text("创建手帐本 ✨")
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
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("新手帐本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
