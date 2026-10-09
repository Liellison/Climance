import XCTest

final class ClimanceUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testSearchSurvivesLayoutChanges() throws {
        #if os(iOS)
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        #endif
        let app = XCUIApplication()
        addUIInterruptionMonitor(withDescription: "Location permission") { alert in
            for title in ["Don’t Allow", "Don't Allow", "Não Permitir"] {
                if alert.buttons[title].exists { alert.buttons[title].tap(); return true }
            }
            return false
        }
        app.launch()
        app.tap()
        if app.tabBars.buttons["Buscar"].exists { app.tabBars.buttons["Buscar"].tap() }
        let input = app.textFields["cityInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["searchButton"].isEnabled)
        input.tap()
        input.typeText("São Paulo")
        XCTAssertTrue(app.buttons["searchButton"].isEnabled)
        capture("Busca compacta")
        #if os(iOS)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        XCTAssertEqual(input.value as? String, "São Paulo")
        capture("Busca em tela larga")
        XCUIDevice.shared.orientation = .portrait
        if app.tabBars.buttons["Buscar"].exists { app.tabBars.buttons["Buscar"].tap() }
        XCTAssertEqual(input.value as? String, "São Paulo")
        #endif
    }

    private func capture(_ name: String) {
        let screenshot = XCTAttachment(screenshot: XCUIApplication().screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
