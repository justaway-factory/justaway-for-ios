import Foundation
import SwifteriOS

struct TwitterUser {
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    
    init(_ json: JSONValue) {
        self.userID = json["id_str"].string ?? ""
        self.screenName = json["screen_name"].string ?? ""
        self.name = json["name"].string ?? ""
        if let url = json["profile_image_url"].string {
            self.profileImageURL = NSURL(string: url.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: nil, range: nil))!
        } else {
            self.profileImageURL = NSURL(string: json["profile_image_url"].string ?? "")!
        }
    }
}