import Foundation

class DataManagerMock : DataManager {
    var importOPMLURL : NSURL? = nil
    var importOPMLProgress : (Double) -> Void = {_ in }
    var importOPMLCompletion : ([Feed]) -> Void = {_ in }
    override func importOPML(opml: NSURL, progress: (Double) -> Void, completion: ([Feed]) -> Void) {
        importOPMLURL = opml
        importOPMLProgress = progress
        importOPMLCompletion = completion
    }

    var newFeedURL: String? = nil
    var newFeedCompletion : (NSError?) -> Void = {_ in }
    override func newFeed(feedURL: String, completion: (NSError?) -> (Void)) -> Feed? {
        newFeedURL = feedURL
        newFeedCompletion = completion
        return nil
    }

    var feedsList : [Feed] = []
    override func feeds() -> [Feed] {
        return feedsList
    }

    override func updateFeeds(completion: (NSError?) -> (Void)) {
        completion(nil)
    }

    override func updateFeedsInBackground(completion: (NSError?) -> (Void)) {
        completion(nil)
    }

    override func updateFeeds(feeds: [Feed], backgroundFetch: Bool, completion: (NSError?)->(Void)) {
        completion(nil)
    }
}