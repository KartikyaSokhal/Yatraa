
import Foundation

@MainActor
final class SavedSitesManager: ObservableObject {

    
    @Published private(set) var savedIDs: Set<String> = []

    private let storageKey = "savedSites_default"

   
    init() {
        load()
    }

   

    func isSaved(_ site: HeritageSite) -> Bool {
        savedIDs.contains(site.id.uuidString)
    }

    func toggleSave(_ site: HeritageSite) {
        let key = site.id.uuidString
        if savedIDs.contains(key) {
            savedIDs.remove(key)
        } else {
            savedIDs.insert(key)
        }
        persist()
    }

    func savedSites(from allSites: [HeritageSite]) -> [HeritageSite] {
        allSites.filter { savedIDs.contains($0.id.uuidString) }
    }

    

    private func load() {
        let stored = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        savedIDs = Set(stored)
    }

    private func persist() {
        UserDefaults.standard.set(Array(savedIDs), forKey: storageKey)
    }
}
