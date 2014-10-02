import UIKit
import XCTest

class KeychainTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Keychain.clear()
    }
    
    override func tearDown() {
        Keychain.clear()
        super.tearDown()
    }
    
    func testExample() {
        let key1 = "testExampleKey1"
        let key2 = "testExampleKey2"
        let saveData = "data".toData()
        
        XCTAssert(Keychain.save(key1, data: saveData), "save")
        XCTAssert(Keychain.save(key2, data: saveData), "save")
        
        XCTAssert(Keychain.load(key1) != nil, "load")
        XCTAssert(Keychain.load(key2) != nil, "load")
        
        let loadData = Keychain.load(key1)!
        
        XCTAssert(loadData.toString() == saveData.stringValue, "load data")
        
        XCTAssert(Keychain.remove(key1), "remove")
        
        XCTAssert(Keychain.load(key1) == nil, "remove data")
        XCTAssert(Keychain.load(key2) != nil, "not remove data")
    }
    
    func testClear() {
        let key = "testClearKey"
        let data = "testClearData".toData()
        
        Keychain.save(key, data: data)
        XCTAssert(Keychain.load(key) != nil, "save data")
        
        Keychain.clear()
        XCTAssert(Keychain.load(key) == nil, "clear data")
    }
    
}

extension String {
    func toData() -> NSData {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
}

extension NSData {
    func toString() -> String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)
    }
    public var stringValue : String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)
    }
}
