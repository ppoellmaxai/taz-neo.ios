//
//  helperFunctions.swift
//  taz.neo.UITests
//
//  Created by Philo.Pöllmann on 1/28/21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//
import XCTest

struct AppElements {
    //Privacy Declaration
    static let gdprHeader = XCUIApplication().webViews.webViews.webViews.otherElements["Datenschutzerklärung"]
    static let acceptGdprBtn = XCUIApplication().staticTexts["Akzeptieren"]
    static let welcomeXBtn = XCUIApplication().otherElements["webViewXBtn"]
    
    //Carousel
    static let firstIssue = XCUIApplication().collectionViews.otherElements["Ausgabe:0"].children(matching: .image).element
    static let thirdIssue = XCUIApplication().collectionViews.otherElements["Ausgabe:2"].children(matching: .image).element
    
    //Sidebar
    static let logoBtn = XCUIApplication().buttons["logo"]
    static let sideBarTbl = XCUIApplication().tables
    
    //Toolbar
    //TODO Setting Accessibility IDs for toolbar buttons
    static let fontBtn = XCUIApplication()/*@START_MENU_TOKEN@*/.toolbars["Toolbar"]/*[[".toolbars[\"Symbolleiste\"]",".toolbars[\"Toolbar\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element(boundBy: 1)
    static let homeBtn = XCUIApplication().toolbars["Toolbar"].children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 2)

    //Authentication Dialog
    static let eMailTextField = XCUIApplication().scrollViews.otherElements.textFields["E-Mail-Adresse oder Abo-ID"]
    static let passwordTextField = XCUIApplication().scrollViews.otherElements.secureTextFields["Passwort"]
    static let signInBtn = XCUIApplication().scrollViews.otherElements.staticTexts["Anmelden"]
}


func waitForEitherElementToExist(elementA: XCUIElement, elementB: XCUIElement, timeout: Double) -> XCUIElement? {
    let startTime = NSDate.timeIntervalSinceReferenceDate
    while (!elementA.exists && !elementB.exists) { // while neither element exists
        if (NSDate.timeIntervalSinceReferenceDate - startTime > timeout) {
            XCTFail("Timed out waiting for either element to exist.")
            break
        }
        sleep(1)
    }

    if elementA.exists { return elementA }
    if elementB.exists { return elementB }
    return nil
}

func waitForElementToExist(test: XCTestCase, element:XCUIElement){
    let predicate = NSPredicate(format: "exists == 1")
    test.expectation(for:predicate, evaluatedWith: element, handler: nil)
    test.waitForExpectations(timeout:30, handler: nil)
}
