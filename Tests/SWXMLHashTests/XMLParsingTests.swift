//
//  XMLParsingTests.swift
//  SWXMLHash
//
//  Copyright (c) 2016 David Mohundro
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import SWXMLHash
import Testing

// swiftlint:disable line_length
// swiftlint:disable file_length
// swiftlint:disable type_body_length

struct XMLParsingTests {
    let xmlToParse = """
        <root>
          <header>header mixed content<title>Test Title Header</title>more mixed content</header>
          <catalog>
            <book id=\"bk101\">
              <author>Gambardella, Matthew</author>
              <title>XML Developer's Guide</title>
              <genre>Computer</genre><price>44.95</price>
              <publish_date>2000-10-01</publish_date>
              <description>An in-depth look at creating applications with XML.</description>
            </book>
            <book id=\"bk102\">
              <author>Ralls, Kim</author>
              <title>Midnight Rain</title>
              <genre>Fantasy</genre>
              <price>5.95</price>
              <publish_date>2000-12-16</publish_date>
              <description>A former architect battles corporate zombies, an evil sorceress, and her own childhood to become queen of the world.</description>
            </book>
            <book id=\"bk103\">
              <author>Corets, Eva</author>
              <title>Maeve Ascendant</title>
              <genre>Fantasy</genre>
              <price>5.95</price>
              <publish_date>2000-11-17</publish_date>
              <description>After the collapse of a nanotechnology society in England, the young survivors lay the foundation for a new society.</description>
            </book>
          </catalog>
        </root>
    """

    var xml: XMLIndexer?

    init() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        xml = XMLHash.parse(xmlToParse)
    }

    @Test
    func shouldBeAbleToParseIndividualElements() {
        #expect(xml!["root"]["header"]["title"].element?.text == "Test Title Header")
    }

    @Test
    func shouldBeAbleToParseIndividualElementsWithStringRawRepresentable() {
        enum Keys: String {
            case root; case header; case title
        }
        #expect(xml![Keys.root][Keys.header][Keys.title].element?.text == "Test Title Header")
    }

    @Test
    func shouldBeAbleToParseElementGroups() {
        #expect(xml!["root"]["catalog"]["book"][1]["author"].element?.text == "Ralls, Kim")
    }

    @Test
    func shouldBeAbleToGetParent() {
        #expect(xml!["root"]["catalog"]["book"][1]["author"].element?.parent != nil)
        #expect(xml!["root"]["catalog"]["book"][1]["author"].element?.parent?.name == "book")
        #expect(xml!["root"]["catalog"]["book"][1]["author"].element?.parent?.attribute(by: "id")?.text == "bk102")
    }

    @Test
    func shouldBeAbleToParseElementGroupsByIndex() {
        // swiftlint:disable:next force_try
        #expect(try! xml!["root"]["catalog"]["book"].byIndex(1)["author"].element?.text == "Ralls, Kim")
    }

    @Test
    func shouldBeAbleToByIndexWithoutGoingOutOfBounds() {
        // swiftlint:disable:next force_try
        #expect(try! xml!["root"]["catalog"]["book"].byIndex(3)["author"].element?.text == nil)
    }

    @Test
    func shouldBeAbleToParseAttributes() {
        #expect(xml!["root"]["catalog"]["book"][1].element?.attribute(by: "id")?.text == "bk102")
    }

    @Test
    func shouldBeAbleToParseAttributesWithStringRawRepresentable() {
        enum Keys: String {
            case root; case catalog; case book; case id
        }
        #expect(xml![Keys.root][Keys.catalog][Keys.book][1].element?.attribute(by: Keys.id)?.text == "bk102")
    }

    @Test
    func shouldBeAbleToLookUpElementsByNameAndAttribute() {
        do {
            let value = try xml!["root"]["catalog"]["book"].withAttribute("id", "bk102")["author"].element?.text
            #expect(value == "Ralls, Kim")
        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func shouldBeAbleToLookUpElementsByNameAndAttributeWithStringRawRepresentable() {
        enum Keys: String {
            case root; case catalog; case book; case id; case bk102; case author
        }
        do {
            let value = try xml![Keys.root][Keys.catalog][Keys.book].withAttribute(Keys.id, Keys.bk102)[Keys.author].element?.text
            #expect(value == "Ralls, Kim")
        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func shouldBeAbleToLookUpElementsByNameAndAttributeCaseInsensitive() {
        do {
            let xmlInsensitive = XMLHash.config({ config in
                config.caseInsensitive = true
            }).parse(xmlToParse)
            let value = try xmlInsensitive["rOOt"]["catalOg"]["bOOk"].withAttribute("iD", "Bk102")["authOr"].element?.text
            #expect(value == "Ralls, Kim")
        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func shouldBeAbleToIterateElementGroups() {
        let result = xml!["root"]["catalog"]["book"].all.map({ $0["genre"].element!.text }).joined(separator: ", ")
        #expect(result == "Computer, Fantasy, Fantasy")
    }

    @Test
    func shouldBeAbleToIterateElementGroupsEvenIfOnlyOneElementIsFound() {
        #expect(xml!["root"]["header"]["title"].all.count == 1)
    }

    @Test
    func shouldBeAbleToIndexElementGroupsEvenIfOnlyOneElementIsFound() {
        #expect(xml!["root"]["header"]["title"][0].element?.text == "Test Title Header")
    }

    @Test
    func shouldBeAbleToIterateUsingForIn() {
        var count = 0
        for _ in xml!["root"]["catalog"]["book"].all {
            count += 1
        }

        #expect(count == 3)
    }

    @Test
    func shouldBeAbleToEnumerateChildren() {
        let result = xml!["root"]["catalog"]["book"][0].children.map({ $0.element!.name }).joined(separator: ", ")
        #expect(result == "author, title, genre, price, publish_date, description")
    }

    @Test
    func shouldBeAbleToHandleMixedContent() {
        #expect(xml!["root"]["header"].element?.text == "header mixed contentmore mixed content")
    }

    @Test
    func shouldBeAbleToIterateOverMixedContent() {
        let mixedContentXml = "<html><body><p>mixed content <i>iteration</i> support</body></html>"
        let parsed = XMLHash.parse(mixedContentXml)
        let element = parsed["html"]["body"]["p"].element
        #expect(element != nil)
        if let element = element {
            let result = element.children.reduce("") { acc, child in
                switch child {
                case let elm as SWXMLHash.XMLElement:
                    let text = elm.text
                    return acc + text
                case let elm as TextElement:
                    return acc + elm.text
                default:
                    Issue.record("Unknown element type")
                    return acc
                }
            }

            #expect(result == "mixed content iteration support")
        }
    }

    @Test
    func shouldBeAbleToRecursiveOutputTextContent() {
        let mixedContentXmlInputs = [
            // From SourceKit cursor info key.annotated_decl
            "<Declaration>typealias SomeHandle = <Type usr=\"s:Su\">UInt</Type></Declaration>",
            "<Declaration>var points: [<Type usr=\"c:objc(cs)Location\">Location</Type>] { get set }</Declaration>",
            // From SourceKit cursor info key.fully_annotated_decl
            "<decl.typealias><syntaxtype.keyword>typealias</syntaxtype.keyword> <decl.name>SomeHandle</decl.name> = <ref.struct usr=\"s:Su\">UInt</ref.struct></decl.typealias>",
            "<decl.var.instance><syntaxtype.keyword>var</syntaxtype.keyword> <decl.name>points</decl.name>: <decl.var.type>[<ref.class usr=\"c:objc(cs)Location\">Location</ref.class>]</decl.var.type> { <syntaxtype.keyword>get</syntaxtype.keyword> <syntaxtype.keyword>set</syntaxtype.keyword> }</decl.var.instance>",
            "<decl.function.method.instance><syntaxtype.keyword>fileprivate</syntaxtype.keyword> <syntaxtype.keyword>func</syntaxtype.keyword> <decl.name>documentedMemberFunc</decl.name>()</decl.function.method.instance>"
        ]

        let recursiveTextOutputs = [
            "typealias SomeHandle = UInt",
            "var points: [Location] { get set }",

            "typealias SomeHandle = UInt",
            "var points: [Location] { get set }",
            "fileprivate func documentedMemberFunc()"
        ]

        for (index, mixedContentXml) in mixedContentXmlInputs.enumerated() {
            #expect(XMLHash.parse(mixedContentXml).element!.recursiveText == recursiveTextOutputs[index])
        }
    }

    @Test
    func shouldHandleInterleavingXMLElements() {
        let interleavedXml = "<html><body><p>one</p><div>two</div><p>three</p><div>four</div></body></html>"
        let parsed = XMLHash.parse(interleavedXml)

        let result = parsed["html"]["body"].children.map({ $0.element!.text }).joined(separator: ", ")
        #expect(result == "one, two, three, four")
    }

    @Test
    func shouldBeAbleToProvideADescriptionForTheDocument() {
        let descriptionXml = "<root><foo><what id=\"myId\">puppies</what></foo></root>"
        let parsed = XMLHash.parse(descriptionXml)

        #expect(parsed.description == "<root><foo><what id=\"myId\">puppies</what></foo></root>")
    }

    @Test
    func shouldBeAbleToGetInnerXML() {
        let testXML = "<root><foo><what id=\"myId\">puppies</what><elems><elem>1</elem><elem>2</elem></elems></foo></root>"
        let parsed = XMLHash.parse(testXML)

        #expect(parsed["root"]["foo"].element!.innerXML == "<what id=\"myId\">puppies</what><elems><elem>1</elem><elem>2</elem></elems>")
    }

    // error handling

    @Test
    func shouldReturnNilWhenKeysDontMatch() {
        #expect(xml!["root"]["what"]["header"]["foo"].element?.name == nil)
    }

    @Test
    func shouldProvideAnErrorObjectWhenKeysDontMatch() {
        var err: IndexingError?
        defer {
            #expect(err != nil)
        }
        do {
            _ = try xml!.byKey("root").byKey("what").byKey("header").byKey("foo")
        } catch let error as IndexingError {
            err = error
        } catch { err = nil }
    }

    /**
     Added Only test coverage for:
    `byKey<K: RawRepresentable>(_ key: K) throws -> XMLIndexer where K.RawValue == String`
     */
    @Test
    func shouldProvideAnErrorObjectWhenKeysDontMatchWithStringRawRepresentable() {
        enum Keys: String {
            case root; case what; case header; case foo
        }
        var err: IndexingError?
        defer {
            #expect(err != nil)
        }
        do {
            _ = try xml!.byKey(Keys.root).byKey(Keys.what).byKey(Keys.header).byKey(Keys.foo)
        } catch let error as IndexingError {
            err = error
        } catch { err = nil }
    }

    @Test
    func shouldProvideAnErrorElementWhenIndexersDontMatch() {
        var err: IndexingError?
        defer {
            #expect(err != nil)
        }
        do {
            _ = try xml!.byKey("what").byKey("subelement").byIndex(5).byKey("nomatch")
        } catch let error as IndexingError {
            err = error
        } catch { err = nil }
    }

    @Test
    func shouldStillReturnErrorsWhenAccessingViaSubscripting() {
        var err: IndexingError?
        switch xml!["what"]["subelement"][5]["nomatch"] {
        case .xmlError(let error):
            err = error
        default:
            err = nil
        }
        #expect(err != nil)
    }

    @Test
    func shouldBeAbleToCreateASubIndexer() {
        let xmlToParse = """
            <root>
                <some-weird-element />
                <another-weird-element />
                <prop1 name="prop1" />
                <prop2 name="prop2" />
                <basicItem id="1234a">
                    <name>item 1</name>
                    <price>1</price>
                </basicItem>
                <prop3 name="prop3" />
                <last-weird-element />
            </root>
        """

        let parser = XMLHash.parse(xmlToParse)

        let subIndexer = parser["root"].filterChildren { _, index in index >= 2 && index <= 5 }

        #expect(subIndexer["some-weird-element"].element == nil)
        #expect(subIndexer["another-weird-element"].element == nil)
        #expect(subIndexer["prop1"].element != nil)
        #expect(subIndexer["prop2"].element != nil)
        #expect(subIndexer["basicItem"].element != nil)
        #expect(subIndexer["prop3"].element != nil)
        #expect(subIndexer["last-weird-element"].element == nil)
    }

    @Test
    func shouldBeAbleToCreateASubIndexerFromFilter() {
        let subIndexer = xml!["root"]["catalog"]["book"][1].filterChildren { elem, _ in
            let filterByNames = ["title", "genre", "price"]
            return filterByNames.contains(elem.name)
        }

        #expect(subIndexer.children[0].element?.name == "title")
        #expect(subIndexer.children[1].element?.name == "genre")
        #expect(subIndexer.children[2].element?.name == "price")

        #expect(subIndexer.children[0].element?.text == "Midnight Rain")
        #expect(subIndexer.children[1].element?.text == "Fantasy")
        #expect(subIndexer.children[2].element?.text == "5.95")
    }

    @Test
    func shouldBeAbleToFilterOnIndexer() {
        let subIndexer = xml!["root"]["catalog"]["book"]
            .filterAll { elem, _ in elem.attribute(by: "id")!.text == "bk102" }
            .filterChildren { _, index in index >= 1 && index <= 3 }

        #expect(subIndexer.children[0].element?.name == "title")
        #expect(subIndexer.children[1].element?.name == "genre")
        #expect(subIndexer.children[2].element?.name == "price")

        #expect(subIndexer.children[0].element?.text == "Midnight Rain")
        #expect(subIndexer.children[1].element?.text == "Fantasy")
        #expect(subIndexer.children[2].element?.text == "5.95")
    }

    @Test
    func shouldThrowErrorForInvalidXML() {
        let invalidXML = "<uh oh>what is this"
        var err: ParsingError?
        let parser = XMLHash.config { config in
            config.detectParsingErrors = true
        }.parse(invalidXML)

        switch parser {
        case .parsingError(let error):
            err = error
        default:
            err = nil
        }

        #expect(err != nil)

#if !(os(Linux) || os(Windows))
        if err != nil {
            #expect(err!.line == 1)
        }
#endif
    }
}

// swiftlint:enable line_length
// swiftlint:enable type_body_length
