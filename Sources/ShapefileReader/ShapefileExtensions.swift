//
//  ShapefileExtensions.swift
//  
//
//  Created by Frederic Schwarz on 25.04.22.
//

import Foundation
import CoreLocation

extension PRJReader {
    func coordinateConverter() throws -> (CGPoint) -> CLLocationCoordinate2D {

        switch cs {
        case is GeographicCS where cs.name.range(of: "wgs.*84", options: [.regularExpression, .caseInsensitive]) != nil:
            return { CLLocationCoordinate2D(latitude: CLLocationDegrees($0.y), longitude: CLLocationDegrees($0.x)) }
        default:
            throw Error.coordinateSystemNotSupported(cs)
        }
    }
}

extension ShapefileReader {
    /// Can be overridden to support coordinate systems other than WGS84.
    open func coordinateConverter() throws -> (CGPoint) -> CLLocationCoordinate2D {

        guard let converter = try prj?.coordinateConverter() else { throw PRJReader.Error.coordinateSystemNotDefined }

        return converter
    }


    public func pointsCoordinatesForShape(at index: Int) throws -> [CLLocationCoordinate2D] {

        guard index < count else { throw Error.noShape(at: index) }

        let converter = try coordinateConverter()

        return self[index].points.map(converter)
    }


    public func mbrCoordinates() throws -> (min: CLLocationCoordinate2D, max: CLLocationCoordinate2D) {

        let converter = try coordinateConverter()

        let min = converter(CGPoint(x: shp.bbox.x_min, y: shp.bbox.y_min))
        let max = converter(CGPoint(x: shp.bbox.x_max, y: shp.bbox.y_max))

        return (min, max)
    }


    public func centerCoordinate() throws -> CLLocationCoordinate2D {

        let mbr = try mbrCoordinates()
        let lat1 = mbr.min.latitude.degreesToRadians
        let lon1 = mbr.min.longitude.degreesToRadians
        let lat2 = mbr.max.latitude.degreesToRadians
        let lon2 = mbr.max.longitude.degreesToRadians
        let x = (cos(lat1) * cos(lon1) + cos(lat2) * cos(lon2)) / 2
        let y = (cos(lat1) * sin(lon1) + cos(lat2) * sin(lon2)) / 2
        let z = (sin(lat1) + sin(lat2)) / 2

        return CLLocationCoordinate2D(latitude: atan2(z, hypot(x, y)).radiansToDegrees, longitude: atan2(y, x).radiansToDegrees)
    }
}

extension CLLocationDegrees {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}
