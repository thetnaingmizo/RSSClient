import Quick
import Nimble
import rNews
import Robot

class ValidatorViewSpec: QuickSpec {
    override func spec() {
        var subject: ValidatorView! = nil

        beforeEach {
            subject = ValidatorView()
        }

        describe("beginValidating") {
            beforeEach {
                subject.beginValidating()
            }

            it("should move to an in-progress validating state") {
                expect(subject.state).to(equal(ValidatorView.ValidatorState.Validating))
            }

            it("should start the progressIndicator") {
                expect(subject.progressIndicator.isAnimating()).to(beTruthy())
            }

            context("upon successful validation") {
                beforeEach {
                    subject.endValidating(true)
                }

                it("should move to a successful validating state") {
                    expect(subject.state).to(equal(ValidatorView.ValidatorState.Valid))
                }

                it("should stop the progressIndicator") {
                    expect(subject.progressIndicator.isAnimating()).to(beFalsy())
                }

                it("should hide the progressIndicator") {
                    RBTimeLapse.advanceMainRunLoop()
                    expect(subject.progressIndicator.hidden).to(beTruthy())
                }
            }

            context("upon failing to validate") {
                beforeEach {
                    subject.endValidating(false)
                }

                it("should move to an invalid validating state") {
                    expect(subject.state).to(equal(ValidatorView.ValidatorState.Invalid))
                }

                it("should stop the progressIndicator") {
                    expect(subject.progressIndicator.isAnimating()).to(beFalsy())
                }

                it("should hide the progressIndicator") {
                    RBTimeLapse.advanceMainRunLoop()
                    expect(subject.progressIndicator.hidden).to(beTruthy())
                }
            }
        }
    }
}
