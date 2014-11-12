//
//  FindFeedViewController.swift
//  RSSClient
//
//  Created by Rachel Brindle on 9/28/14.
//  Copyright (c) 2014 Rachel Brindle. All rights reserved.
//

import UIKit
import WebKit
import Alamofire

class FindFeedViewController: UIViewController, WKNavigationDelegate, UITextFieldDelegate, MWFeedParserDelegate {
    let webContent = WKWebView(forAutoLayout: ())
    let loadingBar = UIProgressView(progressViewStyle: .Bar)
    let navField = UITextField(frame: CGRectMake(0, 0, 200, 30))
    private var rssLink: String? = nil
    
    var addFeedButton: UIBarButtonItem! = nil
    var back: UIBarButtonItem! = nil
    var forward: UIBarButtonItem! = nil
    var reload: UIBarButtonItem! = nil
    var cancelTextEntry : UIBarButtonItem! = nil
    
    var lookForFeeds : Bool = true
    
    var feeds: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webContent.navigationDelegate = self
        self.view.addSubview(webContent)
        webContent.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        webContent.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
                
        back = UIBarButtonItem(title: "<", style: .Plain, target: webContent, action: "goBack")
        forward = UIBarButtonItem(title: ">", style: .Plain, target: webContent, action: "goForward")
        addFeedButton = UIBarButtonItem(title: NSLocalizedString("Add Feed", comment: ""), style: .Plain, target: self, action: "save")
        back.enabled = false
        forward.enabled = false
        addFeedButton.enabled = false
        
        let dismiss = UIBarButtonItem(title: NSLocalizedString("Dismiss", comment: ""), style: .Plain, target: self, action: "dismiss")
        reload = UIBarButtonItem(barButtonSystemItem: .Refresh, target: webContent, action: "reload")
        cancelTextEntry = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .Plain, target: navField, action: "resignFirstResponder")
        cancelTextEntry.tintColor = UIColor.darkTextColor()
        
        self.navigationController?.toolbarHidden = false
        func spacer() -> UIBarButtonItem {
            return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: "")
        }
        if (lookForFeeds) {
            self.toolbarItems = [back, forward, spacer(), dismiss, spacer(), addFeedButton]
        } else {
            self.toolbarItems = [back, forward, spacer(), dismiss]
        }
        
        self.navigationItem.titleView = navField
        navField.delegate = self
        navField.placeholder = "Enter URL"
        navField.backgroundColor = UIColor(white: 0.8, alpha: 0.75)
        navField.layer.cornerRadius = 5
        navField.autocapitalizationType = .None
        navField.keyboardType = .URL
        navField.clearsOnBeginEditing = true
        loadingBar.progress = 0
        
        /*
        if (lookForFeeds) {
        let navFieldShownString = "findfeedviewcontroller.navfield.shown"
            if (NSUserDefaults.standardUserDefaults().boolForKey(navFieldShownString) == false) {
                let popTip = AMPopTip()
                let popTipText = NSAttributedString(string: NSLocalizedString("Enter the URL for the feed or website here", comment: ""),
                                                    attributes: [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)])
                let width = CGRectGetWidth(self.view.bounds) / 2.0
                let size = popTipText.boundingRectWithSize(CGSizeMake(width, CGFloat.max), options: .UsesFontLeading, context: nil).size
                popTip.showAttributedText(popTipText, direction: AMPopTipDirection.Up, maxWidth: ceil(size.width), inView: self.view, fromFrame: CGRectMake(width, -10, 0, 0))
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: navFieldShownString)
            }
        }
        */
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if (lookForFeeds) {
            feeds = DataManager.sharedInstance().feeds().map({return $0.url;})
        }
    }
    
    deinit {
        webContent.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    func dismiss() {
        self.navigationController?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func save() {
        if let rl = rssLink {
            save(rl)
        } else {
            dismiss()
        }
    }
    
    func save(link: String) {
        // show something to indicate we're doing work...
        let loading = LoadingView(frame: self.view.bounds)
        self.view.addSubview(loading)
        loading.msg = NSString.localizedStringWithFormat(NSLocalizedString("Loading feed at %@", comment: ""), link)
        self.navigationController?.toolbarHidden = true
        self.navigationController?.navigationBarHidden = true
        DataManager.sharedInstance().newFeed(link) {(_) in
            loading.removeFromSuperview()
            self.navigationController?.toolbarHidden = false
            self.navigationController?.navigationBarHidden = false
            self.dismiss()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if (keyPath == "estimatedProgress" && object as NSObject == webContent) {
            loadingBar.progress = Float(webContent.estimatedProgress)
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.navigationItem.setRightBarButtonItem(cancelTextEntry, animated: true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        var button : UIBarButtonItem? = nil
        if (webContent.estimatedProgress >= 1.0) {
            button = reload
        }
        self.navigationItem.setRightBarButtonItem(button, animated: true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.text = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if !textField.text.lowercaseString.hasPrefix("http") {
            textField.text = "http://\(textField.text)"
        }
        if let url = NSURL(string: textField.text) {
            self.webContent.loadRequest(NSURLRequest(URL: NSURL(string: textField.text)!))
        }
        if (lookForFeeds) {
            Alamofire.request(.GET, textField.text).response {(_, _, response, error) in
                if let txt = response as? String {
                    let feedParser = MWFeedParser(string: txt)
                    feedParser.feedParseType = ParseTypeInfoOnly
                    feedParser.delegate = self
                    feedParser.parse()
                    let opmlParser = OPMLParser(text: txt)
                    opmlParser.callback = {(items) in
                        feedParser.stopParsing()
                        
                    }
                }
            }
        }
        textField.text = ""
        textField.placeholder = NSLocalizedString("Loading", comment: "")
        textField.resignFirstResponder()
        
        return true
    }
    
    // MARK: - MWFeedParserDelegate
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        parser.stopParsing()
        if (!contains(feeds, info.url.absoluteString!)) {
            let alert = UIAlertController(title: NSLocalizedString("Feed Detected", comment: ""), message: NSString.localizedStringWithFormat(NSLocalizedString("Save %@?", comment: ""), info.url), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Don't Save", comment: ""), style: .Cancel, handler: {(alertAction: UIAlertAction!) in
                print("") // this is bullshit
                alert.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .Default, handler: {(_) in
                alert.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                self.save(info.url.absoluteString!)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView!, didFinishNavigation navigation: WKNavigation!) {
        self.navigationItem.titleView = self.navField
        navField.placeholder = webView.title
        forward.enabled = webView.canGoForward
        back.enabled = webView.canGoBack
        self.navigationItem.rightBarButtonItem = reload
        
        if (lookForFeeds) {
            let discover = NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("findFeeds", ofType: "js")!, encoding: NSUTF8StringEncoding, error: nil)!
            webView.evaluateJavaScript(discover, completionHandler: {(res: AnyObject!, error: NSError?) in
                if let str = res as? String {
                    if (!contains(self.feeds, str)) {
                        self.rssLink = str
                        self.addFeedButton.enabled = true
                    }
                } else {
                    self.rssLink = nil
                }
                if (error != nil) {
                    println("Error executing javascript: \(error)")
                }
            })
        }
    }
    
    func webView(webView: WKWebView!, didFailNavigation navigation: WKNavigation!, withError error: NSError!) {
        self.navigationItem.titleView = self.navField
    }
    
    func webView(webView: WKWebView!, didStartProvisionalNavigation navigation: WKNavigation!) {
        println("loading navigation: \(navigation)")
        loadingBar.progress = 0
        self.navigationItem.titleView = loadingBar
        navField.placeholder = ""
        addFeedButton.enabled = false
    }
}
