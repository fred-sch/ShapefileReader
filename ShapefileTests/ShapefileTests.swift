//
//  ShapefileTests.swift
//  ShapefileTests
//
//  Created by nst on 20/03/16.
//  Copyright © 2016 Nicolas Seriot. All rights reserved.
//  Copyright © 2018 Alexey Demin. All rights reserved.
//

import XCTest


class ShapefileTests: XCTestCase {
    
    static let bundle = Bundle(for: ShapefileTests.self)
    
    let dbfURL = bundle.url(forResource: "Kantone", withExtension: "dbf")!
    let prjURL = bundle.url(forResource: "Kantone", withExtension: "prj")!
    let sbnURL = bundle.url(forResource: "Kantone", withExtension: "sbn")!
    let sbxURL = bundle.url(forResource: "Kantone", withExtension: "sbx")!
    let shpURL = bundle.url(forResource: "Kantone", withExtension: "shp")!
    let xmlURL = bundle.url(forResource: "Kantone", withExtension: "shp.xml")!
    let shxURL = bundle.url(forResource: "Kantone", withExtension: "shx")!
    
    let wktURL = bundle.url(forResource: "Example", withExtension: "wkt")!

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    // http://www.arcgis.com/home/item.html?id=a5067fb3b0b74b188d7b650fa5c64b39
    
    func testRecords() {
        
        let sr = try! ShapefileReader(url: shpURL)

        XCTAssertEqual(sr.dbf!.numberOfRecords, 26)

        let records = Array(sr.dbf!)
        XCTAssertEqual(records.count, 26)

        let rec = try! sr.dbf!.recordAtIndex(1)
        XCTAssertEqual(rec[1] as? String, "BE")

        print("\(#function) pass")
    }

    
    func testShapes() {
        
        let sr = try! ShapefileReader(url: shpURL)

        let shapes = Array(sr.shp)
        XCTAssertEqual(shapes.count, 26)
        
        let shape2 = shapes[2]
        XCTAssertEqual(shape2.shapeType, ShapeType.polygon)
        XCTAssertEqual(shape2.parts.count, 5)
        XCTAssertEqual(shape2.points.count, 531)
        XCTAssert(shape2.bbox.x_max > 0)
        
        XCTAssertEqual(shapes.count, sr.dbf!.count)
    }

    
    func testShx() {
        
        let sr = try! ShapefileReader(url: shpURL)

        let offset = sr.shx!.shapeOffsetAtIndex(2)!
        let (_, shape2_) = try! sr.shp.shapeAtOffset(UInt64(offset))!
        
        let shape2__ = Array(sr.shp)[2]
        let shape2___ = sr[2]

        XCTAssertEqual(shape2_.parts.count, shape2__.parts.count)
        XCTAssertEqual(shape2_.points.count, shape2__.points.count)
        XCTAssertEqual(shape2_.parts.count, shape2___.parts.count)
        XCTAssertEqual(shape2_.points.count, shape2___.points.count)
        
        XCTAssertEqual(sr.dbf!.numberOfRecords, sr.shx!.numberOfShapes)
    }
    
    
    func testPrj() {
        
        let sr = try! ShapefileReader(url: shpURL)
        let cs = sr.prj?.cs.entity as? ProjectedCS
        XCTAssertEqual(cs?.geographicCS.angularUnit.name, "Degree")
        XCTAssertEqual(cs?.geographicCS.angularUnit.conversionFactor, 0.0174532925199433)
        XCTAssertEqual(cs?.parameters?.first { $0.name == "Longitude_Of_Center" }?.value, 7.439583333333333)
        XCTAssertEqual(cs?.parameters?.first { $0.name == "Latitude_Of_Center" }?.value, 46.95240555555556)
    }
    
    
    func testWKTParser() {
        
        let wktData = try! Data(contentsOf: wktURL)
        
        let wktObjects = try! WKTSerialization.wktObjects(with: wktData)
        let filter = { !"\n 1234567890.\"".contains($0) }
        let wkt1 = String(data: wktData, encoding: .utf8)!.filter(filter)
        let wkt2 = wktObjects.first!.description.filter(filter)
        XCTAssertEqual(wkt1, wkt2)
//        print("\n-1-", wkt1, "\n-2-", wkt2, "\n")
    }
    
    
    func testWKTDecoder() {
        
        let wktData = try! Data(contentsOf: wktURL)
        
        let cs = try! WKTDecoder().decode(Varied<CoordinateSystem>.self, from: wktData)
        XCTAssert(cs.entity is CompdCS)
        XCTAssertEqual(((cs.entity as? CompdCS)?.headCS.entity as? ProjectedCS)?.parameters?.count, 5)
    }
    
    
    func testWrongFormats() {
        
        XCTAssertThrowsError(try ShapefileReader(url: dbfURL))
        XCTAssertThrowsError(try ShapefileReader(url: prjURL))
        XCTAssertThrowsError(try ShapefileReader(url: sbnURL))
        XCTAssertThrowsError(try ShapefileReader(url: sbxURL))
        XCTAssertThrowsError(try ShapefileReader(url: xmlURL))
        XCTAssertThrowsError(try ShapefileReader(url: shxURL))
        XCTAssertThrowsError(try ShapefileReader(url: wktURL))

        XCTAssertThrowsError(try SHPReader(url: dbfURL))
        XCTAssertThrowsError(try SHPReader(url: prjURL))
        XCTAssertThrowsError(try SHPReader(url: sbnURL))
        XCTAssertThrowsError(try SHPReader(url: sbxURL))
        XCTAssertThrowsError(try SHPReader(url: xmlURL))
//        XCTAssertThrowsError(try SHPReader(url: shxURL))
        XCTAssertThrowsError(try SHPReader(url: wktURL))

        let shp = try! SHPReader(url: shxURL)
        XCTAssertTrue(Array(shp).isEmpty)
    }
    
    
    func testCrashes() {
        
        // SHP data corruption
        let data = try! Data(contentsOf: shpURL)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test").appendingPathExtension("shp")
        let piece = 1000
        
        // Bitwise cutting
        for i in 0..<piece {
            let d = data[..<(piece - i)]
            try! d.write(to: url, options: .atomic)
            if let sr = try? SHPReader(url: url) {
                _ = Array(sr)
            }
        }
        // Bitwise zeroing
        for i in 0..<piece {
            var d = data[..<piece]
            d[i] = 0
            try! d.write(to: url, options: .atomic)
            if let sr = try? SHPReader(url: url) {
                _ = Array(sr)
            }
        }
        // Bitwise NOT
        for i in 0..<piece {
            var d = data[..<piece]
            d[i] = ~d[i]
            try! d.write(to: url, options: .atomic)
            if let sr = try? SHPReader(url: url) {
                _ = Array(sr)
            }
        }
    }
}
