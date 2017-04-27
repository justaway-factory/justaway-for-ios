import UIKit
import XCTest
import TwitterAPI

class AccountTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AccountSettingsStore.clear()
    }
    
    override func tearDown() {
        AccountSettingsStore.clear()
        super.tearDown()
    }
    
    func testExample() {
        let normalURL = "https://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"
        let biggerURL = "https://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_bigger.png"
        
        let client = OAuthClient(consumerKey: "", consumerSecret: "", accessToken: "", accessTokenSecret: "")
        let account = Account(client: client, userID: "1", screenName: "su_aska", name: "Shinichiro Aska", profileImageURL: URL(string: normalURL)!, profileBannerURL: URL(string: normalURL)!, exToken: "")
        
        XCTAssertEqual(account.screenName, "su_aska")
        
        XCTAssertEqual(account.profileImageBiggerURL?.absoluteString, biggerURL)
        
        XCTAssertTrue(AccountSettingsStore.save(AccountSettings(current: 0, accounts: [account])))
        
//        let accountSettings = AccountSettingsStore.load()
//        
//        XCTAssertEqual(accountSettings.current, 0)
//        
//        XCTAssertEqual(accountSettings.accounts[0].screenName, account.screenName)
//        
//        XCTAssertEqual(accountSettings.account().userID, accountSettings.account(0).userID)
//        
//        AccountSettingsStore.clear()
//        
//        XCTAssertTrue(AccountSettingsStore.load() == nil)
    }
    
}
