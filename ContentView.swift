import SwiftUI
import UniformTypeIdentifiers

// MARK: - Memory Model (Codable for Local Storage)
struct Memory: Identifiable, Codable {
    var id = UUID() // Make `id` mutable and remove default value
    let date: Date
    let rating: Int
    let description: String
    let additionalDetails: String?
}

// MARK: - Function for Color Mapping (Lighter Pastel Shades)
func getColor(for rating: Int) -> Color {
    switch rating {
    case 5: return Color(red: 173/255, green: 216/255, blue: 230/255) // Baby Blue
    case 4: return Color(red: 224/255, green: 187/255, blue: 228/255) // Soft Lavender
    case 3: return Color(red: 255/255, green: 223/255, blue: 186/255) // Light Peach
    case 2: return Color(red: 255/255, green: 192/255, blue: 203/255) // Baby Pink
    case 1: return Color(red: 255/255, green: 182/255, blue: 193/255) // Soft Coral Pink
    default: return Color.gray.opacity(0.4)
    }
}

// MARK: - MemoryStore for Local Storage
class MemoryStore: ObservableObject {
    @Published var memories: [Memory] = [] {
        didSet {
            saveMemories()
        }
    }

    init() {
        loadMemories()
    }

    private let saveKey = "SavedMemories"

    // Load memories from UserDefaults
    private func loadMemories() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([Memory].self, from: data) {
                memories = decoded
            }
        }
    }

    // Save memories to UserDefaults
    private func saveMemories() {
        if let encoded = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    // Add a new memory
    func addMemory(_ memory: Memory) {
        memories.append(memory)
    }

    // Delete a memory
    func deleteMemory(at indexSet: IndexSet) {
        memories.remove(atOffsets: indexSet)
    }

    // Export memories as a .txt file
    func exportMemories() -> String {
        var fileContent = ""
        for memory in memories {
            fileContent += """
            Date: \(memory.date.formatted(date: .abbreviated, time: .omitted))
            Rating: \(String(repeating: "⭐️", count: memory.rating))
            Nutshell: \(memory.description)
            Details: \(memory.additionalDetails ?? "No additional details.")
            --------------------------
            """
        }
        return fileContent
    }
}

// MARK: - Live Gradient Background Modifier
struct AnimatedBackground: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: isDarkMode ?
                              [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)] : // Dark mode gradient
                              [Color.pink.opacity(0.4), Color.blue.opacity(0.4), Color.purple.opacity(0.4)]), // Light mode gradient
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Dark Mode Toggle Button
struct DarkModeToggleButton: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        Button(action: {
            isDarkMode.toggle()
        }) {
            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 20))
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(10)
                .background(isDarkMode ? Color.black.opacity(0.6) : Color.white.opacity(0.6))
                .clipShape(Circle())
                .shadow(radius: 5)
        }
    }
}

// MARK: - Star Rating View
struct StarRatingView: View {
    @ObservedObject var memoryStore: MemoryStore
    @State private var selectedRating: Int = 0
    @State private var description: String = ""
    @State private var additionalDetails: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var showMotivationalPopup = false
    @State private var showRatingAlert = false
    @State private var showDescriptionAlert = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    // Dynamic prompts for detailed input
    let detailedPrompts = [
        1: ["It’s okay to have rough days. Want to talk about it? 💙", "Hugs! What made today tough? 🤗"],
        2: ["Some days are just… days! How was yours? 🌤️", "What small thing made today a little better? 🌱"],
        3: ["A calm and cozy day? What little joys did you find? ☕", "What were the small, nice moments today? 🌼"],
        4: ["Smiles all around! What brightened your day? 🌞", "A pocket full of happiness! What made your heart happy? ❤️"],
        5: ["Best day ever?! Tell me everything! 🎊", "Today’s a star in your story! What made it sparkle? 🌠"]
    ]

    // Encouraging messages for nutshell input
    @State private var encouragingMessage: String = ""

    // Save button phrases
    @State private var saveButtonText: String = "Save Memory"

    let saveButtonPhrases = [
        "Lock This Moment Forever! 🔒",
        "Tuck This Memory in.. ❤️",
        "Another Page in Your Story 📖"
    ]

    // Motivational messages for pop-up
    let motivationalMessages = [
        1: ["Tough days happen, and you're doing your best. Tomorrow is a fresh start! 🌱", "Sending virtual hugs! Things will get better. 💙"],
        2: ["Life has its ups and downs. Keep going, you're doing great! 🌼", "Even small wins count! Keep shining! ✨"],
        3: ["Another day, another memory. Keep writing your story! 📖", "Your thoughts matter. Thanks for sharing! 💬"],
        4: ["Yay! Cherish today’s happy moments. 😊", "Another beautiful day in your journal! Keep the good vibes coming! 🌞"],
        5: ["Woohoo! Today was fantastic! Keep spreading the joy! 🎉", "Another golden moment saved! May tomorrow be just as great! 💖"]
    ]

    var body: some View {
        ZStack {
            AnimatedBackground()

            VStack(spacing: 20) {
                Text("How was your day?")
                    .font(.custom("Bradley Hand Bold", size: 32))
                    .padding(.top, 40)
                    .foregroundColor(isDarkMode ? .white : .black)

                // Emoji Rating (Colorful Smileys)
                VStack {
                    HStack(spacing: 15) {
                        ForEach(1..<6) { star in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedRating = star
                                }
                            }) {
                                Text(getEmoji(for: star))
                                    .font(.system(size: 50))
                                    .scaleEffect(selectedRating == star ? 1.2 : 1.0)
                            }
                        }
                    }
                    if showRatingAlert && selectedRating == 0 {
                        Text("Please rate your day!")
                            .font(.custom("Bradley Hand Bold", size: 16))
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                }
                .padding(.bottom, 20)

                // Memory Entry Fields
                VStack(spacing: 15) {
                    // One-line input for "Describe your day in a nutshell"
                    VStack(alignment: .leading) {
                        TextField("Tell about your day in a nutshell...", text: $description)
                            .font(.body)
                            .padding()
                            .background(isDarkMode ? Color.gray.opacity(0.2) : Color.white.opacity(0.9))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(isDarkMode ? Color.white.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: description) { newValue in
                                if newValue.count > 50 {
                                    description = String(newValue.prefix(50))
                                }
                            }
                        if description.isEmpty && showDescriptionAlert {
                            Text("Please tell about your day!")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text(description.count == 50 ? getEncouragingMessage(for: selectedRating) : "\(50 - description.count) characters left")
                                .font(.caption)
                                .foregroundColor(isDarkMode ? .white.opacity(0.6) : .gray)
                        }
                    }

                    // Multi-line input for detailed entry
                    TextEditor(text: $additionalDetails)
                        .font(.custom("Bradley Hand Bold", size: 16))
                        .frame(minHeight: 100, maxHeight: .infinity)
                        .padding()
                        .background(isDarkMode ? Color.gray.opacity(0.2) : Color.white.opacity(0.9))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(isDarkMode ? Color.white.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Text(getDetailedPlaceholder(for: selectedRating))
                                .font(.body)
                                .foregroundColor(isDarkMode ? .white.opacity(0.5) : .gray.opacity(0.5))
                                .padding(20)
                                .opacity(additionalDetails.isEmpty ? 1 : 0),
                            alignment: .topLeading
                        )
                }
                .padding(.horizontal)

                // Submit Button
                Button(action: {
                    if selectedRating == 0 {
                        showRatingAlert = true
                    } else if description.isEmpty {
                        showDescriptionAlert = true
                    } else {
                        let memory = Memory(date: Date(), rating: selectedRating, description: description, additionalDetails: additionalDetails.isEmpty ? nil : additionalDetails)
                        memoryStore.addMemory(memory)
                        showMotivationalPopup = true
                    }
                }) {
                    Text(saveButtonText)
                        .font(.custom("Bradley Hand Bold", size: 22))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: isDarkMode ?
                                                   [Color.blue.opacity(0.6), Color.purple.opacity(0.6)] :
                                                   [Color.blue.opacity(0.4), Color.purple.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(isDarkMode ? .white : .white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .disabled(selectedRating == 0 || description.isEmpty)
            }
            .alert(isPresented: $showRatingAlert) {
                Alert(
                    title: Text("Oops!"),
                    message: Text("Please rate your day!"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showDescriptionAlert) {
                Alert(
                    title: Text("Oops!"),
                    message: Text("Please tell about your day in a nutshell!"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showMotivationalPopup) {
                Alert(
                    title: Text("Memory Saved!"),
                    message: Text(motivationalMessages[selectedRating]?.randomElement() ?? "Your memory has been saved. 💖"),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .onAppear {
                // Set static encouraging message and save button text
                encouragingMessage = getEncouragingMessage(for: selectedRating)
                saveButtonText = saveButtonPhrases.randomElement() ?? "Save Memory"
            }
        }
    }

    // Get emoji for rating
    private func getEmoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😡" // Red
        case 2: return "😐" // Orange
        case 3: return "😊" // Yellow
        case 4: return "😄" // Light Green
        case 5: return "😍" // Green
        default: return "⭐️"
        }
    }

    // Get encouraging message based on rating
    private func getEncouragingMessage(for rating: Int) -> String {
        switch rating {
        case 1: return "Want to spill more tea? Let it all out below! ☕🔥"
        case 2: return "It's okay to vent. Share more below if you want. 💙"
        case 3: return "Feeling meh? You can add more details below. 🤔"
        case 4: return "Ooh, sounds nice! Share the best part below! 🌟"
        case 5: return "This sounds amazing! Tell me all about it! 🎉"
        default: return "That's all you can type here! Tell me more below. 😊"
        }
    }

    // Get detailed placeholder based on rating
    private func getDetailedPlaceholder(for rating: Int) -> String {
        switch rating {
        case 1: return "It’s okay to have rough days. Want to talk about it? 💙 Sending Virtual Hugs! What made today tough? 🤗"
        case 2: return "Some days are just… days! How was yours? 🌤️ What small thing made today a little better? 🌱"
        case 3: return "Another day, another memory. Keep writing your story! 📖 Your thoughts matter. Thanks for sharing! 💬"
        case 4: return "Smiles all around! What brightened your day? 🌞 A pocket full of happiness! What made your heart happy? ❤️"
        case 5: return "Best day ever?! Tell me everything! 🎊 Today’s a star in your story! What made it sparkle? 🌠"
        default: return "Tell me more about your day..."
        }
    }
}

// MARK: - Memory List View
struct MemoryListView: View {
    @ObservedObject var memoryStore: MemoryStore
    @State private var expandedMemoryID: UUID?
    @State private var isExporting = false
    @State private var searchText: String = "" // For search functionality
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        ZStack {
            AnimatedBackground()

            VStack {
                // Search Bar
                TextField("Search memories...", text: $searchText)
                    .font(.body)
                    .padding()
                    .background(isDarkMode ? Color.gray.opacity(0.2) : Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isDarkMode ? Color.white.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 10) {
                        if memoryStore.memories.isEmpty {
                            Text("No memories yet :( \nTap 'Add Memory' \n to make new ones !")
                                .multilineTextAlignment(.center)
                                .font(.custom("Bradley Hand Bold", size: 30))
                                .foregroundColor(isDarkMode ? .white.opacity(0.8) : .black.opacity(0.8))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                        }

                        // Filtered memories based on search text
                        ForEach(filteredMemories.reversed()) { memory in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.custom("Bradley Hand Bold", size: 18))
                                        .foregroundColor(isDarkMode ? .white : .black)
                                    Spacer()
                                    Text(String(repeating: getEmoji(for: memory.rating), count: 1))
                                        .font(.system(size: 22))
                                }

                                Text(memory.description)
                                    .font(.custom("Bradley Hand Bold", size: 16))
                                    .foregroundColor(isDarkMode ? .white : .black)

                                if expandedMemoryID == memory.id {
                                    Text(memory.additionalDetails ?? "No additional details.")
                                        .font(.custom("Bradley Hand Bold", size: 16))
                                        .foregroundColor(isDarkMode ? .white : .black)
                                        .transition(.opacity)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity) // Full Width Box
                            .background(isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.8) : getColor(for: memory.rating))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(isDarkMode ? Color.white.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onTapGesture {
                                withAnimation {
                                    expandedMemoryID = (expandedMemoryID == memory.id) ? nil : memory.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Export Button
                Button(action: {
                    isExporting = true
                }) {
                    Text("Take Your Memories Elsewhere")
                        .font(.custom("Bradley Hand Bold", size: 18))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: isDarkMode ?
                                                   [Color.purple.opacity(0.6), Color.blue.opacity(0.6)] :
                                                   [Color.purple.opacity(0.4), Color.blue.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(isDarkMode ? .white : .white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .fileExporter(isPresented: $isExporting, document: TextFile(contents: memoryStore.exportMemories()), contentType: .plainText) { result in
                    switch result {
                    case .success(let url):
                        print("Exported to \(url)")
                    case .failure(let error):
                        print("Export failed: \(error)")
                    }
                }
            }
        }
    }

    // Filter memories based on search text
    private var filteredMemories: [Memory] {
        if searchText.isEmpty {
            return memoryStore.memories // Return all memories if search text is empty
        } else {
            return memoryStore.memories.filter { memory in
                memory.description.localizedCaseInsensitiveContains(searchText) ||
                memory.date.formatted(date: .abbreviated, time: .omitted).localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // Get emoji for rating
    private func getEmoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😡" // Red
        case 2: return "😐" // Orange
        case 3: return "😊" // Yellow
        case 4: return "😄" // Light Green
        case 5: return "😍" // Green
        default: return "⭐️"
        }
    }
}

// MARK: - TextFile for Exporting
struct TextFile: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var contents: String

    init(contents: String) {
        self.contents = contents
    }

    init(configuration: ReadConfiguration) throws {
        contents = ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: contents.data(using: .utf8)!)
    }
}

// MARK: - About View
struct AboutView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        ZStack {
            AnimatedBackground()
            ScrollView { // Add ScrollView here to enable scrolling
                VStack {
                    Text("About This App")
                        .font(.custom("Bradley Hand Bold", size: 40))
                        .foregroundColor(isDarkMode ? .white : .white)
                        .padding(.bottom, 15)

                    Text("Memories: Capture, Reflect, Cherish\n\nMemories is a thoughtfully designed journaling app that empowers users to document their daily experiences with simplicity and elegance. By combining intuitive design with interactive features, the app encourages users to reflect on their day, rate their mood, and preserve meaningful moments in a personalized way.\n\nKey Features:\n- Daily Journaling: Log memories with a rating system, a brief description, and optional details for deeper reflection.\n- Dynamic Visuals: Enjoy a visually engaging experience with color-coded ratings, animated gradients, and a seamless dark mode for comfortable use in any setting.\n- Motivational Prompts: Receive tailored prompts and encouraging messages based on your mood, making journaling a positive and uplifting experience.\n- Export Functionality: Save your memories as a text file, allowing you to keep a personal archive of your entries.\n\nDeveloped as a submission for the Apple Swift Student Challenge 2025, Memories showcases the potential of SwiftUI and the power of creativity in app development. It reflects a commitment to learning, innovation, and the pursuit of excellence in technology.")
                        .font(.body) // Adjusted font size for better readability
                        .foregroundColor(isDarkMode ? .white.opacity(0.8) : .black.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .lineSpacing(5) // Added line spacing for better readability
                }
                .frame(maxWidth: .infinity) // Ensure the VStack takes the full width
            }
        }
    }
}

// MARK: - Home Screen
struct ContentView: View {
    @StateObject private var memoryStore = MemoryStore()
    @State private var isShowingMemoryEntry = false
    @State private var isShowingAboutPage = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    // Random phrases for buttons
    @State private var addMemoryButtonText: String = "Add Memory"
    @State private var viewMemoriesButtonText: String = "View Memories"

    let addMemoryPhrases = [
        "Treasure a New Moment ✨",
        "Seal A New Memory Today 💖",
        "Jot Down Today’s Magic! 📖"
    ]

    let viewMemoriesPhrases = [
        "Flip Through Your Happy Moments 📖",
        "Relive the Magic of Yesterday ✨",
        "Walk Down Memory Lane 🌸"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()

                VStack(spacing: 20) {
                    // Dark Mode Toggle Button (Top-Right Corner)
                    HStack {
                        Spacer()
                        DarkModeToggleButton()
                            .padding(.trailing, 20)
                            .padding(.top, 10)
                    }

                    Spacer()

                    // Title and Slogan
                    VStack {
                        Text("Memories")
                            .font(.custom("Bradley Hand Bold", size: 60))
                            .foregroundColor(isDarkMode ? .white : .white)
                            .shadow(radius: 5)

                        Text("Cherish Your Special Moments")
                            .font(.custom("Bradley Hand Bold", size: 18))
                            .foregroundColor(isDarkMode ? .white.opacity(0.8) : .white.opacity(0.8))
                    }
                    .padding(.top, 20)

                    Spacer()

                    // Static Buttons
                    VStack(spacing: 15) {
                        // Add Memory Button
                        Button(action: { isShowingMemoryEntry = true }) {
                            Text(addMemoryButtonText)
                                .font(.custom("Bradley Hand Bold", size: 22))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(colors: isDarkMode ?
                                                           [Color.purple.opacity(0.6), Color.blue.opacity(0.6)] :
                                                           [Color.pink.opacity(0.4), Color.purple.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(isDarkMode ? .white : .white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $isShowingMemoryEntry) {
                            StarRatingView(memoryStore: memoryStore)
                        }

                        // View Memories Button
                        NavigationLink(destination: MemoryListView(memoryStore: memoryStore)) {
                            Text(viewMemoriesButtonText)
                                .font(.custom("Bradley Hand Bold", size: 22))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(colors: isDarkMode ?
                                                           [Color.blue.opacity(0.6), Color.purple.opacity(0.6)] :
                                                           [Color.purple.opacity(0.4), Color.blue.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(isDarkMode ? .white : .white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Footer Text
                    Button(action: { isShowingAboutPage = true }) {
                        Text("Made with ❤️ for Apple Swift Challenge")
                            .font(.caption)
                            .foregroundColor(isDarkMode ? .white.opacity(0.6) : .black.opacity(0.6))
                    }
                    .sheet(isPresented: $isShowingAboutPage) {
                        AboutView()
                    }
                }
            }
            .onAppear {
                // Randomize button text on app launch
                addMemoryButtonText = addMemoryPhrases.randomElement() ?? "Add Memory"
                viewMemoriesButtonText = viewMemoriesPhrases.randomElement() ?? "View Memories"
            }
            .preferredColorScheme(isDarkMode ? .dark : .light) // Apply Dark Mode
        }
    }
}
