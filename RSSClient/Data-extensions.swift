//
//  Data-extensions.swift
//  RSSClient
//
//  Created by Rachel Brindle on 11/26/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

import Foundation

extension Feed {
    func feedImage() -> Image? {
        if self.image == nil { return nil }
        return self.image as? Image
    }
    
    func unreadArticles() -> UInt {
        return self.allArticles().reduce(0) {
            return $0 + ($1.read ? 0 : 1)
        }
    }
    
    func unreadArticles(dataManager: DataManager) -> UInt {
        return allArticles(dataManager).reduce(0) {
            return $0 + ($1.read ? 0 : 1)
        }
    }
    
    func allArticles() -> [Article] {
        let possibleArticles = Array(self.articles ?? Set()) as? [Article]
        return possibleArticles ?? []
    }
    
    func allArticles(dataManager: DataManager) -> [Article] {
        if let query = self.query {
            return dataManager.articlesMatchingQuery(query, feed: self)
        } else {
            return allArticles()
        }
    }
    
    func isQueryFeed() -> Bool {
        return self.query != nil
    }
    
    func feedTitle() -> String? {
        return reduce(allTags(), self.title) {
            if $1.hasPrefix("~") {
                return $1.substringFromIndex($1.startIndex.successor())
            }
            return $0
        }
    }
    
    func feedSummary() -> String? {
        return reduce(allTags(), self.summary) {
            if $1.hasPrefix("`") {
                return $1.substringFromIndex($1.startIndex.successor())
            }
            return $0
        }
    }
    
    func allTags() -> [String] {
        let possibleTags = self.tags as? [String]
        return possibleTags ?? []
    }
    
    func asDict() -> [String: AnyObject] {
        var ret = asDictNoArticles()
        var theArticles : [[String: AnyObject]] = []
        for article in allArticles() {
            theArticles.append(article.asDictNoFeed())
        }
        ret["articles"] = theArticles
        return ret
    }
    
    func asDictNoArticles() -> [String: AnyObject] {
        var ret : [String: AnyObject] = [:]
        ret["title"] = title ?? ""
        ret["url"] = url ?? ""
        ret["summary"] = summary ?? ""
        ret["query"] = query ?? ""
        ret["tags"] = allTags()
        ret["id"] = self.objectID.description
        ret["remainingWait"] = remainingWait ?? 0
        ret["waitPeriod"] = waitPeriod ?? 0
        return ret
    }
    
    func waitPeriodInRefreshes(waitPeriod: Int) -> Int {
        var ret = 0, next = 1
        let wait = max(0, waitPeriod - 2)
        for i in 0..<wait {
            (ret, next) = (next, ret+next)
        }
        return ret
    }
}

extension Article {
    func allFlags() -> [String] {
        let possibleFlags = self.flags as? [String]
        return possibleFlags ?? []
    }
    
    func allEnclosures() -> [Enclosure] {
        let possibleEnclosures = Array(self.enclosures ?? Set()) as? [Enclosure]
        return possibleEnclosures ?? []
    }
    
    func asDict() -> [String: AnyObject] {
        var ret = asDictNoFeed()
        if let f = feed {
            ret["feed"] = f.asDictNoArticles()
        }
        return ret
    }
    
    func asDictNoFeed() -> [String: AnyObject] {
        var ret : [String: AnyObject] = [:]
        ret["title"] = title ?? ""
        ret["link"] = link ?? ""
        ret["summary"] = summary ?? ""
        ret["author"] = author ?? ""
        ret["published"] = published?.description ?? ""
        ret["updatedAt"] = updatedAt?.description ?? ""
        ret["identifier"] = objectID.URIRepresentation()
        ret["content"] = content ?? ""
        ret["read"] = read
        ret["flags"] = allFlags()
        ret["id"] = self.objectID.description
        return ret
    }
}