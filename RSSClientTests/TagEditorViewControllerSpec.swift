import Quick
import Nimble
import Ra
import rNews
import Robot

class TagEditorViewControllerSpec: QuickSpec {
    override func spec() {
        var injector: Injector! = nil
        var dataManager = DataManagerMock()
        var subject: TagEditorViewController! = nil
        var navigationController: UINavigationController! = nil
        let rootViewController = UIViewController()

        var feed = Feed(title: "title", url: NSURL(string: ""), summary: "", query: nil, tags: [], waitPeriod: nil, remainingWait: nil, articles: [], image: nil)

        beforeEach {
            injector = Injector()
            dataManager = DataManagerMock()
            injector.bind(DataManager.self, to: dataManager)

            subject = injector.create(TagEditorViewController.self) as! TagEditorViewController
            navigationController = UINavigationController(rootViewController: rootViewController)
            navigationController.pushViewController(subject, animated: false)

            feed = Feed(title: "title", url: NSURL(string: ""), summary: "", query: nil, tags: [], waitPeriod: nil, remainingWait: nil, articles: [], image: nil)
            subject.feed = feed

            subject.view.layoutIfNeeded()
            expect(navigationController.topViewController).to(equal(subject))
        }

        it("should should set the title to the feed's title") {
            expect(subject.navigationItem.title).to(equal("title"))
        }

        it("should have a save button") {
            expect(subject.navigationItem.rightBarButtonItem?.title).to(equal("Save"))
        }

        describe("tapping the save button") {
            context("when there is data to save") {
                beforeEach {
                    subject.tagPicker.textField(subject.tagPicker.textField, shouldChangeCharactersInRange: NSMakeRange(0, 0), replacementString: "a")
                    subject.navigationItem.rightBarButtonItem?.tap()
                }

                it("should save the feed, with the added tag") {
                    let newFeed = Feed(title: "title", url: NSURL(string: ""), summary: "", query: nil, tags: ["a"], waitPeriod: nil, remainingWait: nil, articles: [], image: nil)
                    expect(dataManager.lastSavedFeed).to(equal(newFeed))
                }

                it("should pop the navigation controller") {
                    expect(navigationController.topViewController).toEventually(equal(rootViewController))
                }
            }

            context("when there is not data to save") {
                it("should not even be enabled") {
                    expect(subject.navigationItem.rightBarButtonItem?.enabled).to(beFalsy())
                }
            }
        }
    }
}
