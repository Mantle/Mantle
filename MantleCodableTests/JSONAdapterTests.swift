import XCTest
@testable import MantleCodable

private struct Person: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case name
        case nickName = "nick_name"
        case age
    }

    let name: String
    let nickName: String?
    let age: Int
}

private enum PersonValidationError: Error, Equatable {
    case emptyName
}

private struct ValidatedPerson: Codable, JSONValidating {
    let name: String

    func validate() throws {
        if name.isEmpty {
            throw PersonValidationError.emptyName
        }
    }
}

final class JSONAdapterTests: XCTestCase {
    func testDecodesModelFromJSONDictionary() throws {
        let json: [String: Any] = ["name": "Ada", "nick_name": "Countess", "age": 36]
        let person = try JSONAdapter.model(of: Person.self, fromJSONDictionary: json)
        XCTAssertEqual(person, Person(name: "Ada", nickName: "Countess", age: 36))
    }

    func testEncodesModelToJSONDictionary() throws {
        let person = Person(name: "Ada", nickName: nil, age: 36)
        let json = try JSONAdapter.jsonDictionary(from: person)
        XCTAssertEqual(json["name"] as? String, "Ada")
        XCTAssertEqual(json["age"] as? Int, 36)
        XCTAssertNil(json["nick_name"])
    }

    func testRoundTripsArraysOfModels() throws {
        let jsonArray: [[String: Any]] = [
            ["name": "Ada", "age": 36],
            ["name": "Alan", "age": 41]
        ]
        let people = try JSONAdapter.models(of: Person.self, fromJSONArray: jsonArray)
        XCTAssertEqual(people.map { $0.name }, ["Ada", "Alan"])

        let backToJSON = try JSONAdapter.jsonArray(from: people)
        XCTAssertEqual(backToJSON.count, 2)
    }

    func testValidationFailureIsSurfaced() {
        let json: [String: Any] = ["name": ""]
        XCTAssertThrowsError(try JSONAdapter.model(of: ValidatedPerson.self, fromJSONDictionary: json)) { error in
            XCTAssertEqual(error as? PersonValidationError, .emptyName)
        }
    }
}
