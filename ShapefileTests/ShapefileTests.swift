//
//  ShapefileTests.swift
//  ShapefileTests
//
//  Created by nst on 20/03/16.
//  Copyright © 2016 Nicolas Seriot. All rights reserved.
//

import XCTest


class ShapefileTests: XCTestCase {
    
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
        let url = Bundle(for: ShapefileTests.self).url(forResource: "Kantone", withExtension: "shp")!
        
        let sr = try! ShapefileReader(url: url)

        XCTAssertEqual(sr.dbf!.numberOfRecords, 26)

        let records = try! sr.dbf!.allRecords()
        XCTAssertEqual(records.count, 26)

        let rec = try! sr.dbf!.recordAtIndex(1)
        XCTAssertEqual(rec[1] as? String, "BE")

        print("\(#function) pass")
    }

    
    func testShapes() {
        let url = Bundle(for: ShapefileTests.self).url(forResource: "Kantone", withExtension: "shp")!
        
        let sr = try! ShapefileReader(url: url)

        let shapes = sr.shp.allShapes()
        XCTAssertEqual(shapes.count, 26)
        
        let shape2 = shapes[2]
        XCTAssertEqual(shape2.shapeType, ShapeType.polygon)
        XCTAssertEqual(shape2.parts.count, 5)
        XCTAssertEqual(shape2.points.count, 531)
        XCTAssert(shape2.bbox.x_max > 0)
        
        XCTAssertEqual(sr.shp.allShapes().count, try! sr.dbf!.allRecords().count)
    }

    
    func testShx() {
        let url = Bundle(for: ShapefileTests.self).url(forResource: "Kantone", withExtension: "shp")!
        
        let sr = try! ShapefileReader(url: url)

        let offset = sr.shx!.shapeOffsetAtIndex(2)!
        let (_, shape2_) = try! sr.shp.shapeAtOffset(UInt64(offset))!
        
        let shape2__ = sr.shp.allShapes()[2]
        let shape2___ = sr[2]!

        XCTAssertEqual(shape2_.parts.count, shape2__.parts.count)
        XCTAssertEqual(shape2_.points.count, shape2__.points.count)
        XCTAssertEqual(shape2_.parts.count, shape2___.parts.count)
        XCTAssertEqual(shape2_.points.count, shape2___.points.count)
        
        XCTAssertEqual(sr.dbf!.numberOfRecords, sr.shx!.numberOfShapes)
    }
    
    
    func testPrj() {
        let url = Bundle(for: ShapefileTests.self).url(forResource: "Kantone", withExtension: "shp")!
        
        let sr = try! ShapefileReader(url: url)
        let cs = sr.prj?.cs.entity as? ProjectedCS
        XCTAssertEqual(cs?.geographicCS.angularUnit.name, "Degree")
        XCTAssertEqual(cs?.geographicCS.angularUnit.conversionFactor, 0.0174532925199433)
        XCTAssertEqual(cs?.parameters?.first { $0.name == "Longitude_Of_Center" }?.value, 7.439583333333333)
        XCTAssertEqual(cs?.parameters?.first { $0.name == "Latitude_Of_Center" }?.value, 46.95240555555556)
    }
    
    
    func testWKTParser() {
        let wktData = try! Data(contentsOf: Bundle(for: type(of: self)).url(forResource: "Example", withExtension: "wkt")!)
        
        let wktObjects = try! WKTSerialization.wktObjects(with: wktData)
        let filter = { !"\n 1234567890.\"".contains($0) }
        let wkt1 = String(data: wktData, encoding: .utf8)!.filter(filter)
        let wkt2 = wktObjects.first!.description.filter(filter)
        XCTAssertEqual(wkt1, wkt2)
//        print("\n-1-", wkt1, "\n-2-", wkt2, "\n")
    }
    
    
    func testWKTDecoder() {
        let wktData = try! Data(contentsOf: Bundle(for: type(of: self)).url(forResource: "Example", withExtension: "wkt")!)
        
        let cs = try! WKTDecoder().decode(Varied<CoordinateSystem>.self, from: wktData)
        XCTAssert(cs.entity is CompdCS)
        XCTAssertEqual(((cs.entity as? CompdCS)?.headCS.entity as? ProjectedCS)?.parameters?.count, 5)
    }
}
