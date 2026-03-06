import SwiftUI
import SwiftData

// MARK: - 成就系统视图
struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var achievements: [Achievement]
    @Query private var profiles: [UserProfile]
    
    @State private var showingCongrats = false
    @State private var newAchievement: Achievement?
    
    var userProfile: UserProfile? {
        profiles.first
    }
    
    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var totalCount: Int {
        achievements.count
    }
    
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 成就进度卡片
                        achievementProgressCard
                        
                        // 成就网格
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(achievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("成就徽章 💎")
            .onAppear {
                initializeAchievements()
                checkAchievements()
            }
            .alert("🎉 成就解锁！", isPresented: $showingCongrats) {
                Button("太棒了！") {
                    newAchievement = nil
                }
            } message: {
                if let achievement = newAchievement {
                    Text("\(achievement.icon) \(achievement.name)\n\(achievement.description)")
                }
            }
        }
    }
    
    // 成就进度卡片
    private var achievementProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("收集进度")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(unlockedCount) / \(totalCount) 成就")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(unlockedCount) / CGFloat(max(totalCount, 1)))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(Double(unlockedCount) / Double(max(totalCount, 1)) * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * CGFloat(unlockedCount) / CGFloat(max(totalCount, 1)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [CuteColors.pink, Color(hex: "#FF69B4")!],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .pink.opacity(0.4), radius: 8)
        .padding()
    }
    
    // 初始化成就
    private func initializeAchievements() {
        guard achievements.isEmpty else { return }
        
        for preset in presetAchievements {
            let achievement = Achievement(
                name: preset.name,
                description: preset.desc,
                icon: preset.icon,
                conditionType: preset.condition,
                conditionValue: preset.value
            )
            modelContext.insert(achievement)
        }
        
        // 创建用户档案
        if profiles.isEmpty {
            let profile = UserProfile()
            modelContext.insert(profile)
        }
    }
    
    // 检查成就达成
    private func checkAchievements() {
        guard let profile = userProfile else { return }
        
        // 更新连续天数
        let calendar = Calendar.current
        if let lastDate = profile.lastActiveDate as Date?,
           calendar.isDateInToday(lastDate) {
            // 今天已经活跃过
        } else if let lastDate = profile.lastActiveDate as Date?,
                  calendar.isDateInYesterday(lastDate) {
            // 昨天活跃过，连续天数+1
            profile.consecutiveDays += 1
        } else {
            // 中断了，重新开始
            profile.consecutiveDays = 1
        }
        profile.lastActiveDate = Date()
        
        // 检查各项成就
        for achievement in achievements where !achievement.isUnlocked {
            var conditionMet = false
            
            switch achievement.conditionType {
            case "收集数量":
                conditionMet = profile.totalPatternsCount >= achievement.conditionValue
            case "收藏数量":
                // 需要查询收藏数量
                break
            case "手帐本数量":
                // 需要查询手帐本数量
                break
            case "手帐页数":
                // 需要查询页面数量
                break
            case "连续天数":
                conditionMet = profile.consecutiveDays >= achievement.conditionValue
            case "标签数量":
                // 需要查询标签数量
                break
            default:
                break
            }
            
            if conditionMet {
                achievement.isUnlocked = true
                achievement.unlockedAt = Date()
                newAchievement = achievement
                showingCongrats = true
            }
        }
    }
}

// MARK: - 成就卡片组件
struct AchievementCard: View {
    @Bindable var achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? 
                          LinearGradient(colors: [CuteColors.pink, Color(hex: "#FF69B4")!], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                
                Text(achievement.icon)
                    .font(.system(size: 30))
                    .opacity(achievement.isUnlocked ? 1 : 0.4)
            }
            
            // 名称
            Text(achievement.name)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                .lineLimit(1)
            
            // 描述
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // 解锁状态
            if achievement.isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                    Text("已解锁")
                        .font(.caption)
                }
                .foregroundColor(CuteColors.mint)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: achievement.isUnlocked ? .pink.opacity(0.2) : .black.opacity(0.05), radius: 4)
    }
}

// MARK: - 个人页面（显示成就入口）
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PatternItem.createdAt, order: .reverse) private var patterns: [PatternItem]
    @Query private var books: [JournalBook]
    
    @State private var showingAchievements = false
    
    var totalPages: Int {
        books.reduce(0) { $0 + $1.pages.count }
    }
    
    var favoriteCount: Int {
        patterns.filter { $0.isFavorite }.count
    }
    
    var allTags: [String] {
        Array(Set(patterns.flatMap { $0.tags })).count > 0 ? Array(Set(patterns.flatMap { $0.tags })) : []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#FFF0F5").opacity(0.6), Color(hex: "#E0F2FE").opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 统计卡片
                        statsSection
                        
                        // 成就入口
                        achievementSection
                        
                        // 设置入口
                        settingsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("我的主页 💕")
            .sheet(isPresented: $showingAchievements) {
                AchievementsView()
            }
        }
    }
    
    // 统计区域
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("收集统计")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(icon: "photo.stack", title: "图案收藏", value: "\(patterns.count)", color: CuteColors.pink)
                StatCard(icon: "heart.fill", title: "我的收藏", value: "\(favoriteCount)", color: .red)
                StatCard(icon: "book.closed.fill", title: "手帐本", value: "\(books.count)", color: CuteColors.lavender)
                StatCard(icon: "doc.text.fill", title: "手帐页数", value: "\(totalPages)", color: CuteColors.mint)
            }
        }
    }
    
    // 成就区域
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("成就徽章")
                .font(.headline)
            
            Button {
                showingAchievements = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(CuteColors.pink)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("查看我的成就")
                            .font(.system(.body, design: .rounded, weight: .medium))
                        
                        Text("收集更多图案，解锁成就！")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .pink.opacity(0.2), radius: 4)
            }
        }
    }
    
    // 设置区域
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("其他")
                .font(.headline)
            
            VStack(spacing: 0) {
                SettingsRow(icon: "paintbrush.pointed.fill", title: "外观设置", color: CuteColors.lavender)
                Divider()
                SettingsRow(icon: "info.circle.fill", title: "关于", color: .gray)
            }
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// 统计卡片
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// 设置行
struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
