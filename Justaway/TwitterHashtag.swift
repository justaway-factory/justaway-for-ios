import Foundation
import SwiftyJSON

struct TwitterHashtag {
    let text: String
    let indices: [Int]

    init(_ json: JSON) {
        self.text = json["text"].string ?? ""
        self.indices = json["indices"].array?.map({ $0.int ?? 0 }) ?? [Int]()
    }

    init(json: [String: AnyObject]) {
        self.text = json["text"] as? String ?? ""
        self.indices = json["indices"] as? [Int] ?? []
    }

    init(_ dictionary: [String: AnyObject]) {
        self.text = dictionary["text"] as? String ?? ""
        self.indices = dictionary["indices"] as? [Int] ?? []
    }

    var dictionaryValue: [String: AnyObject] {
        return [
            "text": text as AnyObject,
            "indices": indices as AnyObject
        ]
    }
}
