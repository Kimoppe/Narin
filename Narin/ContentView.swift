import SwiftUI
import Combine
import AVFoundation
import VisionKit
import Vision

// MARK: - Platform Color Compatibility
extension Color {
    static var groupedBackground: Color {
        #if os(iOS)
        Color(UIColor.systemGroupedBackground)
        #else
        Color(NSColor.windowBackgroundColor)
        #endif
    }
    static var secondaryGroupedBackground: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemGroupedBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }
}

// MARK: - Data Models
struct Subject: Identifiable {
    let id = UUID()
    let name: String
    let examDate: Date?
    let color: Color
}

struct Material: Identifiable {
    let id = UUID()
    let title: String
    let type: MaterialType
    let subjectName: String
    let date: Date

    enum MaterialType: String, CaseIterable {
        case pdf = "PDF"
        case recording = "録音"
        case note = "ノート"
        case scan = "スキャン"
        case pastExam = "過去問"

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .recording: return "mic.fill"
            case .note: return "note.text"
            case .scan: return "camera.fill"
            case .pastExam: return "clock.arrow.circlepath"
            }
        }

        var color: Color {
            switch self {
            case .pdf: return .blue
            case .recording: return .red
            case .note: return .orange
            case .scan: return .purple
            case .pastExam: return .green
            }
        }
    }
}

// MARK: - AppData
final class AppData: ObservableObject {
    @Published var subjects: [Subject] = [
        Subject(name: "解剖学", examDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()), color: .blue),
        Subject(name: "生理学", examDate: Calendar.current.date(byAdding: .day, value: 25, to: Date()), color: .green),
        Subject(name: "生化学", examDate: Calendar.current.date(byAdding: .day, value: 8, to: Date()), color: .orange),
        Subject(name: "病理学", examDate: Calendar.current.date(byAdding: .day, value: 40, to: Date()), color: .purple),
    ]

    @Published var materials: [Material] = [
        Material(title: "神経系の構造と機能", type: .pdf, subjectName: "解剖学", date: Date()),
        Material(title: "第3回講義録音", type: .recording, subjectName: "生理学", date: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!),
        Material(title: "酵素反応まとめ", type: .note, subjectName: "生化学", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        Material(title: "2024年度 解剖学 過去問", type: .pastExam, subjectName: "解剖学", date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
        Material(title: "組織切片スキャン", type: .scan, subjectName: "病理学", date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        Material(title: "上肢の骨格系", type: .pdf, subjectName: "解剖学", date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!),
        Material(title: "心臓の働き 講義録音", type: .recording, subjectName: "生理学", date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!),
        Material(title: "2023年度 生理学 過去問", type: .pastExam, subjectName: "生理学", date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!),
    ]
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var appData = AppData()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(0)
            LibraryView()
                .tabItem { Label("ライブラリ", systemImage: "folder.fill") }
                .tag(1)
            RecordingView()
                .tabItem { Label("録音", systemImage: "mic.fill") }
                .tag(2)
            AIView()
                .tabItem { Label("AI", systemImage: "sparkles") }
                .tag(3)
            ScanView()
                .tabItem { Label("スキャン", systemImage: "camera.fill") }
                .tag(4)
        }
        .tint(Color(red: 0.2, green: 0.4, blue: 0.3))
        .environmentObject(appData)
    }
}

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject var appData: AppData
    @State private var selectedSubject: String? = nil

    var filteredMaterials: [Material] {
        guard let selected = selectedSubject else { return appData.materials }
        return appData.materials.filter { $0.subjectName == selected }
    }

    var nextExam: Subject? {
        appData.subjects
            .filter { $0.examDate != nil && $0.examDate! > Date() }
            .sorted { $0.examDate! < $1.examDate! }
            .first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let exam = nextExam, let examDate = exam.examDate {
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: examDate).day ?? 0
                        CountdownCard(subjectName: exam.name, daysLeft: days, color: exam.color)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("科目")
                            .font(.headline)
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                SubjectPill(name: "すべて", color: .gray, isSelected: selectedSubject == nil) {
                                    selectedSubject = nil
                                }
                                ForEach(appData.subjects) { subject in
                                    SubjectPill(name: subject.name, color: subject.color, isSelected: selectedSubject == subject.name) {
                                        selectedSubject = selectedSubject == subject.name ? nil : subject.name
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("最近の資料")
                            .font(.headline)
                            .padding(.horizontal)
                        if filteredMaterials.isEmpty {
                            Text("資料がありません")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(filteredMaterials) { material in
                                MaterialRow(material: material)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Narin")
            .background(Color.groupedBackground)
        }
    }
}

// MARK: - LibraryView
struct LibraryView: View {
    @EnvironmentObject var appData: AppData
    @State private var searchText = ""
    @State private var selectedType: Material.MaterialType? = nil
    @State private var selectedSubject: String? = nil

    var filteredMaterials: [Material] {
        appData.materials.filter { material in
            let matchesSearch = searchText.isEmpty ||
                material.title.localizedCaseInsensitiveContains(searchText) ||
                material.subjectName.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedType == nil || material.type == selectedType
            let matchesSubject = selectedSubject == nil || material.subjectName == selectedSubject
            return matchesSearch && matchesType && matchesSubject
        }
        .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("資料を検索...", text: $searchText)
                }
                .padding(10)
                .background(Color.secondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "すべて", icon: "square.grid.2x2", isSelected: selectedType == nil) {
                            selectedType = nil
                        }
                        ForEach(Material.MaterialType.allCases, id: \.self) { type in
                            FilterChip(label: type.rawValue, icon: type.icon, isSelected: selectedType == type) {
                                selectedType = selectedType == type ? nil : type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        SubjectPill(name: "すべての科目", color: .gray, isSelected: selectedSubject == nil) {
                            selectedSubject = nil
                        }
                        ForEach(appData.subjects) { subject in
                            SubjectPill(name: subject.name, color: subject.color, isSelected: selectedSubject == subject.name) {
                                selectedSubject = selectedSubject == subject.name ? nil : subject.name
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                Divider()

                if filteredMaterials.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("資料が見つかりません")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("検索条件を変更してみてください")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            HStack {
                                Text("\(filteredMaterials.count)件の資料")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            ForEach(filteredMaterials) { material in
                                MaterialRow(material: material)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("ライブラリ")
            .background(Color.groupedBackground)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // 後で追加UIを実装
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.3))
                    }
                }
                #endif
            }
        }
    }
}

// MARK: - FilterChip
struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    private let deepGreen = Color(red: 0.2, green: 0.4, blue: 0.3)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(isSelected ? deepGreen : deepGreen.opacity(0.1)))
            .foregroundStyle(isSelected ? .white : deepGreen)
        }
    }
}

// MARK: - RecordingManager
class RecordingManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var waveformSamples: [CGFloat] = Array(repeating: 0.05, count: 40)
    @Published var transcribedText = ""
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var waveformTimer: Timer?
    private var recordingURL: URL?

    func startRecording() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("セッション設定エラー: \(error)")
            return
        }
        #endif

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        recordingURL = documentsPath.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            elapsedTime = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.elapsedTime += 1
            }
            waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateWaveform()
            }
        } catch {
            print("録音開始エラー: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        waveformTimer?.invalidate()
        isRecording = false
        transcribedText = "（録音が完了しました。文字起こし機能はWhisper API連携後に有効になります）"
        waveformSamples = Array(repeating: 0.05, count: 40)
    }

    private func updateWaveform() {
        audioRecorder?.updateMeters()
        let power = audioRecorder?.averagePower(forChannel: 0) ?? -60
        let normalizedValue = max(0.05, min(1.0, CGFloat((power + 60) / 60)))
        waveformSamples.removeFirst()
        waveformSamples.append(normalizedValue)
    }

    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - RecordingView
struct RecordingView: View {
    @StateObject private var manager = RecordingManager()
    @State private var showPermissionAlert = false
    private let deepGreen = Color(red: 0.2, green: 0.4, blue: 0.3)
    private let terracotta = Color(red: 0.76, green: 0.4, blue: 0.3)

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Text(manager.formattedTime(manager.elapsedTime))
                    .font(.system(size: 64, weight: .thin, design: .monospaced))
                    .foregroundStyle(manager.isRecording ? terracotta : Color.secondary)
                    .animation(.easeInOut, value: manager.isRecording)

                WaveformView(samples: manager.waveformSamples, isRecording: manager.isRecording)
                    .frame(height: 80)
                    .padding(.horizontal)

                Button {
                    if manager.isRecording {
                        manager.stopRecording()
                    } else {
                        checkPermissionAndRecord()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(manager.isRecording ? terracotta : deepGreen)
                            .frame(width: 80, height: 80)
                            .shadow(
                                color: manager.isRecording ? terracotta.opacity(0.4) : deepGreen.opacity(0.4),
                                radius: 12
                            )
                        if manager.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.white)
                        }
                    }
                }
                .scaleEffect(manager.isRecording ? 1.05 : 1.0)
                .animation(
                    manager.isRecording
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: manager.isRecording
                )

                Text(manager.isRecording ? "タップして停止" : "タップして録音開始")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if !manager.transcribedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .foregroundStyle(deepGreen)
                            Text("文字起こし")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                        ScrollView {
                            Text(manager.transcribedText)
                                .font(.body)
                                .padding()
                        }
                        .frame(maxHeight: 160)
                        .background(Color.secondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("録音")
            .background(Color.groupedBackground)
            .alert("マイクへのアクセス", isPresented: $showPermissionAlert) {
                Button("設定を開く") {
                    #if os(iOS)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    #endif
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("録音するにはマイクへのアクセス許可が必要です。設定から許可してください。")
            }
        }
    }

    func checkPermissionAndRecord() {
        #if os(iOS)
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            manager.startRecording()
        case .denied:
            showPermissionAlert = true
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted { self.manager.startRecording() }
                    else { self.showPermissionAlert = true }
                }
            }
        @unknown default:
            break
        }
        #else
        manager.startRecording()
        #endif
    }
}

// MARK: - WaveformView
struct WaveformView: View {
    let samples: [CGFloat]
    let isRecording: Bool
    private let deepGreen = Color(red: 0.2, green: 0.4, blue: 0.3)
    private let terracotta = Color(red: 0.76, green: 0.4, blue: 0.3)

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 2) {
                ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                    Capsule()
                        .fill(isRecording
                              ? terracotta.opacity(0.7 + Double(sample) * 0.3)
                              : deepGreen.opacity(0.3))
                        .frame(
                            width: (geo.size.width - CGFloat(samples.count - 1) * 2) / CGFloat(samples.count),
                            height: max(4, geo.size.height * sample)
                        )
                        .animation(.easeInOut(duration: 0.1), value: sample)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - AnalysisType
enum AnalysisType: String, CaseIterable {
    case summary = "要約"
    case predictedQuestions = "予想問題"
    case flashcards = "フラッシュカード"
    case qa = "Q&A"

    var icon: String {
        switch self {
        case .summary: return "text.alignleft"
        case .predictedQuestions: return "questionmark.circle.fill"
        case .flashcards: return "rectangle.on.rectangle.fill"
        case .qa: return "bubble.left.and.bubble.right.fill"
        }
    }

    var description: String {
        switch self {
        case .summary: return "重要ポイントを整理"
        case .predictedQuestions: return "試験対策問題を生成"
        case .flashcards: return "暗記カードを作成"
        case .qa: return "Q&A形式で整理"
        }
    }
}

// MARK: - OllamaClient
class OllamaClient: ObservableObject {
    @AppStorage("ollamaHost") var host = "localhost"
    @AppStorage("ollamaModel") var model = "qwen2.5"

    private struct RequestBody: Codable {
        let model: String
        let prompt: String
        let stream: Bool
    }

    private struct ResponseBody: Codable {
        let response: String
    }

    enum OllamaError: LocalizedError {
        case notConfigured
        case connectionFailed
        case apiError(Int)
        case decodingError

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "OllamaのホストIPが設定されていません。設定画面から入力してください。"
            case .connectionFailed:
                return "Ollamaサーバーに接続できません。MacでOllamaが起動しているか確認してください。"
            case .apiError(let code):
                return "Ollama APIエラー（ステータス: \(code)）。"
            case .decodingError:
                return "レスポンスの解析に失敗しました。"
            }
        }
    }

    var baseURL: String { "http://\(host):11434" }

    func analyze(material: Material, analysisType: AnalysisType) async throws -> String {
        guard !host.isEmpty else { throw OllamaError.notConfigured }

        let prompt = buildPrompt(material: material, type: analysisType)
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw OllamaError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let body = RequestBody(model: model, prompt: prompt, stream: false)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.connectionFailed
        }
        guard httpResponse.statusCode == 200 else {
            throw OllamaError.apiError(httpResponse.statusCode)
        }

        let responseBody = try JSONDecoder().decode(ResponseBody.self, from: data)
        return responseBody.response
    }

    func checkConnection() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    private func buildPrompt(material: Material, type: AnalysisType) -> String {
        let context = "資料タイトル：\(material.title)\n科目：\(material.subjectName)\n種類：\(material.type.rawValue)"
        switch type {
        case .summary:
            return "\(context)\n\nこの資料の内容を医学部学生向けに要約してください。重要なポイントを箇条書きで5〜10個挙げてください。"
        case .predictedQuestions:
            return "\(context)\n\nこの資料から試験に出そうな予想問題を5問作成してください。各問題に解答と解説も含めてください。"
        case .flashcards:
            return "\(context)\n\nこの資料から暗記に役立つフラッシュカードを10枚作成してください。「表：[キーワード]」「裏：[説明]」の形式で記載してください。"
        case .qa:
            return "\(context)\n\nこの資料について、よくある質問とその回答を5セット作成してください。Q&A形式で記載してください。"
        }
    }
}

// MARK: - AIView
struct AIView: View {
    @EnvironmentObject var appData: AppData
    @StateObject private var ollamaClient = OllamaClient()
    @State private var selectedMaterial: Material? = nil
    @State private var selectedAnalysisType: AnalysisType = .summary
    @State private var analysisResult = ""
    @State private var isAnalyzing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSettings = false
    @State private var isConnected: Bool? = nil

    private let deepGreen = Color(red: 0.2, green: 0.4, blue: 0.3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Ollamaサーバー接続状態バナー
                    HStack(spacing: 12) {
                        if isConnected == nil {
                            ProgressView().scaleEffect(0.8)
                            Text("Ollamaに接続中…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if isConnected == true {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ollama接続済み")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("モデル: \(ollamaClient.model)  (\(ollamaClient.host))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ollamaに接続できません")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("MacでOllamaを起動し、設定でIPを確認してください")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("設定") { showSettings = true }
                            .font(.caption)
                            .buttonStyle(.borderedProminent)
                            .tint(deepGreen)
                    }
                    .padding()
                    .background(isConnected == true ? Color.green.opacity(0.08) : Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke((isConnected == true ? Color.green : Color.orange).opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .task {
                        isConnected = await ollamaClient.checkConnection()
                    }

                    // 資料選択
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分析する資料")
                            .font(.headline)
                            .padding(.horizontal)

                        Menu {
                            Button("資料を選択してください") { selectedMaterial = nil }
                            Divider()
                            ForEach(appData.materials) { material in
                                Button {
                                    selectedMaterial = material
                                } label: {
                                    Label(material.title, systemImage: material.type.icon)
                                }
                            }
                        } label: {
                            HStack {
                                if let material = selectedMaterial {
                                    Image(systemName: material.type.icon)
                                        .foregroundStyle(material.type.color)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(material.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        Text("\(material.subjectName) · \(material.type.rawValue)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Image(systemName: "doc.badge.plus")
                                        .foregroundStyle(deepGreen)
                                    Text("資料を選択してください")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .background(Color.secondaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }

                    // 分析タイプ選択
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分析タイプ")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(AnalysisType.allCases, id: \.self) { type in
                                AnalysisTypeCard(
                                    type: type,
                                    isSelected: selectedAnalysisType == type
                                ) {
                                    selectedAnalysisType = type
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 分析ボタン
                    Button {
                        Task { await performAnalysis() }
                    } label: {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isAnalyzing ? "分析中..." : "AIで分析する")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedMaterial == nil ? Color.gray : deepGreen)
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(selectedMaterial == nil || isAnalyzing)
                    .padding(.horizontal)

                    // 分析結果
                    if !analysisResult.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(deepGreen)
                                Text("分析結果")
                                    .font(.headline)
                                Spacer()
                                Button {
                                    #if os(iOS)
                                    UIPasteboard.general.string = analysisResult
                                    #endif
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundStyle(deepGreen)
                                }
                            }
                            .padding(.horizontal)

                            Text(analysisResult)
                                .font(.body)
                                .padding()
                                .background(Color.secondaryGroupedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("AI分析")
            .background(Color.groupedBackground)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(deepGreen)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    func performAnalysis() async {
        guard let material = selectedMaterial else { return }
        isAnalyzing = true
        analysisResult = ""

        do {
            let result = try await ollamaClient.analyze(material: material, analysisType: selectedAnalysisType)
            await MainActor.run {
                analysisResult = result
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isAnalyzing = false
            }
        }
    }
}

// MARK: - AnalysisTypeCard
struct AnalysisTypeCard: View {
    let type: AnalysisType
    let isSelected: Bool
    let action: () -> Void
    private let deepGreen = Color(red: 0.2, green: 0.4, blue: 0.3)

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : deepGreen)
                VStack(alignment: .leading, spacing: 3) {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .primary)
                    Text(type.description)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? deepGreen : deepGreen.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? deepGreen : deepGreen.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - ScanView
struct ScanView: View {
    @EnvironmentObject var appData: AppData
    @State private var showCamera = false
    @State private var scannedText = ""
    @State private var isProcessing = false
    @State private var selectedSubject = ""

    private let deepGreen = Color(red: 0.2, green: 0.4, blue: 0.3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // スキャンボタン
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(deepGreen.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 44))
                                    .foregroundStyle(deepGreen)
                            }
                            Text("資料をスキャン")
                                .font(.headline)
                                .foregroundStyle(deepGreen)
                            Text("カメラで撮影してテキストを自動抽出")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(deepGreen.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(
                                            deepGreen.opacity(0.3),
                                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                        )
                                )
                        )
                    }
                    .padding(.horizontal)

                    if isProcessing {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("テキスト抽出中...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else if !scannedText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("抽出テキスト", systemImage: "text.viewfinder")
                                    .font(.headline)
                                    .foregroundStyle(deepGreen)
                                Spacer()
                                Text("\(scannedText.count)文字")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)

                            ScrollView {
                                Text(scannedText)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                            .frame(maxHeight: 200)
                            .background(Color.secondaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)

                            // 科目選択
                            VStack(alignment: .leading, spacing: 8) {
                                Text("科目を選択")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(appData.subjects) { subject in
                                            SubjectPill(
                                                name: subject.name,
                                                color: subject.color,
                                                isSelected: selectedSubject == subject.name
                                            ) {
                                                selectedSubject = subject.name
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            Button {
                                saveScannedMaterial()
                            } label: {
                                Label("ライブラリに保存", systemImage: "square.and.arrow.down.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedSubject.isEmpty ? Color.gray : deepGreen)
                                    )
                                    .foregroundStyle(.white)
                                    .fontWeight(.semibold)
                            }
                            .disabled(selectedSubject.isEmpty)
                            .padding(.horizontal)
                        }
                    } else {
                        // 使い方ガイド
                        VStack(spacing: 16) {
                            ForEach([
                                ("1", "camera.fill", "紙の資料をカメラで撮影"),
                                ("2", "text.viewfinder", "OCRでテキストを自動抽出"),
                                ("3", "folder.fill", "科目を選んでライブラリに保存"),
                            ], id: \.0) { step, icon, text in
                                HStack(spacing: 14) {
                                    Text(step)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(deepGreen))
                                        .foregroundStyle(.white)
                                    Image(systemName: icon)
                                        .foregroundStyle(deepGreen)
                                        .frame(width: 24)
                                    Text(text)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color.secondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // データ損失警告
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("原本は必ず手元に保管してください")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("スキャン")
            .background(Color.groupedBackground)
            .sheet(isPresented: $showCamera) {
                #if os(iOS)
                DocumentScannerView(scannedText: $scannedText, isProcessing: $isProcessing)
                #endif
            }
        }
    }

    func saveScannedMaterial() {
        guard !selectedSubject.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let dateStr = formatter.string(from: Date())
        let newMaterial = Material(
            title: "スキャン資料 \(dateStr)",
            type: .scan,
            subjectName: selectedSubject,
            date: Date()
        )
        appData.materials.insert(newMaterial, at: 0)
        scannedText = ""
        selectedSubject = ""
    }
}

// MARK: - DocumentScannerView (iOS only)
#if os(iOS)
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Binding var isProcessing: Bool
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            parent.dismiss()
            parent.isProcessing = true

            Task {
                var fullText = ""
                for i in 0..<scan.pageCount {
                    let image = scan.imageOfPage(at: i)
                    if let text = await recognizeText(from: image) {
                        fullText += text + "\n\n"
                    }
                }
                await MainActor.run {
                    parent.scannedText = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
                    parent.isProcessing = false
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.dismiss()
        }

        func recognizeText(from image: UIImage) async -> String? {
            guard let cgImage = image.cgImage else { return nil }

            return await withCheckedContinuation { continuation in
                let request = VNRecognizeTextRequest { request, _ in
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(returning: nil)
                        return
                    }
                    let text = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")
                    continuation.resume(returning: text)
                }
                request.recognitionLanguages = ["ja-JP", "en-US"]
                request.recognitionLevel = .accurate

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }
    }
}
#endif

// MARK: - SettingsView
struct SettingsView: View {
    @AppStorage("ollamaHost") private var host = "localhost"
    @AppStorage("ollamaModel") private var model = "qwen2.5"
    @State private var tempHost = ""
    @State private var tempModel = ""
    @State private var isConnected: Bool? = nil
    @State private var isTesting = false
    @Environment(\.dismiss) private var dismiss

    private let deepGreen = Color(red: 0.2, green: 0.4, blue: 0.3)
    private let commonModels = ["qwen2.5", "llama3.2", "gemma2", "phi3", "mistral", "llama3.1"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("例: 192.168.1.5", text: $tempHost)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                } header: {
                    Text("OllamaサーバーのIPアドレス")
                } footer: {
                    Text("MacとiPhoneを同じWi-Fiに接続してください。MacのIPはシステム設定 > Wi-Fi で確認できます。\niPhoneから同じMacに繋ぐ場合は「localhost」のままでOKです（シミュレータ使用時）。")
                }

                Section {
                    Picker("モデル", selection: $tempModel) {
                        ForEach(commonModels, id: \.self) { m in
                            Text(m).tag(m)
                        }
                    }
                    TextField("カスタムモデル名", text: $tempModel)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                } header: {
                    Text("モデル")
                } footer: {
                    Text("Ollamaにインストール済みのモデル名を入力してください（ollama list で確認）。")
                }

                Section {
                    Button {
                        Task {
                            isTesting = true
                            let client = OllamaClient()
                            client.host = tempHost
                            isConnected = await client.checkConnection()
                            isTesting = false
                        }
                    } label: {
                        HStack {
                            Text("接続テスト")
                            Spacer()
                            if isTesting {
                                ProgressView().scaleEffect(0.8)
                            } else if let connected = isConnected {
                                Image(systemName: connected ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(connected ? .green : .red)
                                Text(connected ? "接続OK" : "接続失敗")
                                    .foregroundStyle(connected ? .green : .red)
                            }
                        }
                    }
                    .foregroundStyle(deepGreen)
                }

                Section {
                    Button {
                        host = tempHost
                        model = tempModel
                        dismiss()
                    } label: {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                    }
                    .listRowBackground(deepGreen)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("データ損失警告", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("スキャンや取り込みを行った資料の原本は、必ず手元に保管してください。アプリのデータが失われた場合、復元できないことがあります。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("設定")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(deepGreen)
                }
                #endif
            }
            .onAppear {
                tempHost = host
                tempModel = model
            }
        }
    }
}

// MARK: - Shared Components
struct CountdownCard: View {
    let subjectName: String
    let daysLeft: Int
    let color: Color

    var urgencyColor: Color {
        if daysLeft <= 7 { return .red }
        if daysLeft <= 14 { return .orange }
        return color
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("次の試験")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(subjectName)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(daysLeft)")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(urgencyColor)
                Text("日後")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(urgencyColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(urgencyColor.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct SubjectPill: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? color : color.opacity(0.1)))
                .foregroundStyle(isSelected ? .white : color)
        }
    }
}

struct MaterialRow: View {
    let material: Material

    var timeAgo: String {
        let diff = Calendar.current.dateComponents([.hour, .day], from: material.date, to: Date())
        if let day = diff.day, day > 0 { return "\(day)日前" }
        if let hour = diff.hour, hour > 0 { return "\(hour)時間前" }
        return "たった今"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: material.type.icon)
                .font(.system(size: 18))
                .foregroundStyle(material.type.color)
                .frame(width: 40, height: 40)
                .background(material.type.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(material.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(material.subjectName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(material.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(material.type.color)
                }
            }
            Spacer()
            Text(timeAgo)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
