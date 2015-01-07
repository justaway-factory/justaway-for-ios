import Foundation
import KeyClip

class AccountSettingsCache {
    struct Static {
        static let instance: AccountSettingsCache = AccountSettingsCache()
    }
    class var sharedInstance: AccountSettingsCache {
        return Static.instance
    }
    private var settings: AccountSettings?
}

class AccountSettingsStore {
    
    // MARK: - Types
    
    struct Constants {
        static let keychainKey = "AccountService"
    }
    
    class func get() -> AccountSettings? {
        if let settings = AccountSettingsCache.sharedInstance.settings {
            return settings
        } else {
            return load()
        }
    }
    
    // MARK: - Public Methods
    
    class func save(settings: AccountSettings) -> Bool {
        assert(settings.accounts.count > 0, "settings.accounts.count is zero")
        assert(settings.accounts.count > settings.current, "current out of range")
        
        AccountSettingsCache.sharedInstance.settings = settings
        
        return KeyClip.save(Constants.keychainKey, dictionary: settings.dictionaryValue)
    }
    
    class func load() -> AccountSettings? {
        if let data = KeyClip.load("AccountService") as NSDictionary? {
            AccountSettingsCache.sharedInstance.settings = AccountSettings(data)
        } else {
            return nil
        }
        
        return AccountSettingsCache.sharedInstance.settings
    }
    
    class func clear() {
        AccountSettingsCache.sharedInstance.settings = nil
        
        KeyClip.delete(Constants.keychainKey)
    }
    
}