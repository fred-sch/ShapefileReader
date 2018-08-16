//
//  CoordinateSystem.swift
//  Shapefile
//
//  Created by Alexey Demin on 2018-08-07.
//  Copyright © 2018 Alexey Demin. All rights reserved.
//

// Non-strict implementation of OGC 01-009

import Foundation


protocol WKTEntity: Decodable {
    
    static var keyword: String { get }
}


struct Varied<T>: Decodable {
    
    private static var supportedTypes: [WKTEntity.Type] {
        switch T.self {
        case is CoordinateSystem.Protocol:
            return [GeographicCS.self, ProjectedCS.self, GeocentricCS.self, VertCS.self, CompdCS.self, FittedCS.self, LocalCS.self]
        case is MathTransform.Protocol:
            return [ParamMT.self, ConcatMT.self, InvMT.self, PassthroughMT.self]
        default:
            return [Parameter.self, Projection.self, Datum.self, Spheroid.self, PrimeMeridian.self, Unit.self, Authority.self, VertDatum.self, Axis.self, ToWGS84.self, LocalDatum.self]
        }
    }
    
    private static func type(for keyword: String) -> WKTEntity.Type? {
        return supportedTypes.first { $0.keyword == keyword }
    }

    let entity: T?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let keyword = try container.decode(String.self)
        let type = Varied<T>.type(for: keyword)
        let entity = try type?.init(from: decoder)
        self.entity = entity as? T
    }
}


protocol CoordinateSystem: WKTEntity {
    
    var name: String { get }
}


protocol MathTransform: WKTEntity { }


struct TwinAxes: Decodable {
    
    let axis1: Axis
    let axis2: Axis
}


struct TripleAxes: Decodable {
    
    let axis1: Axis
    let axis2: Axis
    let axis3: Axis
}


struct GeographicCS: CoordinateSystem {
    
    static let keyword = "GEOGCS"
    
    let name: String
    let datum: Datum
    let primeMeridian: PrimeMeridian
    let angularUnit: Unit
    let twinAxes: TwinAxes?
    let authority: Authority?
}


struct ProjectedCS: CoordinateSystem {
    
    static let keyword = "PROJCS"
    
    let name: String
    let geographicCS: GeographicCS
    let projection: Projection
    let parameters: [Parameter]?
    let linearUnit: Unit
    let twinAxes: TwinAxes?
    let authority: Authority?
}


struct GeocentricCS: CoordinateSystem {
    
    static let keyword = "GEOCCS"
    
    let name: String
    let datum: Datum
    let primeMeridian: PrimeMeridian
    let linearUnit: Unit
    let tripleAxes: TripleAxes?
    let authority: Authority?
}


struct VertCS: CoordinateSystem {
    
    static let keyword = "VERT_CS"
    
    let name: String
    let vertDatum: VertDatum
    let linearUnit: Unit
    let axis: Axis?
    let authority: Authority?
}


struct CompdCS: CoordinateSystem {
    
    static let keyword = "COMPD_CS"
    
    let name: String
    let headCS: Varied<CoordinateSystem>
    let tailCS: Varied<CoordinateSystem>
    let authority: Authority?
}


struct FittedCS: CoordinateSystem {
    
    static let keyword = "FITTED_CS"
    
    let name: String
    let toBase: Varied<MathTransform>
    let baseCS: Varied<CoordinateSystem>
}


struct LocalCS: CoordinateSystem {
    
    static let keyword = "LOCAL_CS"
    
    let name: String
    let localDatum: LocalDatum
    let unit: Unit
    let axis: Axis
    let axes: [Axis]?
    let authority: Authority?
}


struct Parameter: WKTEntity {
    
    static let keyword = "PARAMETER"
    
    let name: String
    let value: Double
}


struct Projection: WKTEntity {
    
    static let keyword = "PROJECTION"
    
    let name: String
    let authority: Authority?
}


struct Datum: WKTEntity {
    
    static let keyword = "DATUM"
    
    let name: String
    let spheroid: Spheroid
    let toWGS84: ToWGS84?
    let authority: Authority?
}


struct Spheroid: WKTEntity {
    
    static let keyword = "SPHEROID"
    
    let name: String
    let semiMajorAxis: Double
    let inverseFlattening: Double
    let authority: Authority?
}


struct PrimeMeridian: WKTEntity {
    
    static let keyword = "PRIMEM"
    
    let name: String
    let longitude: Double
    let authority: Authority?
}


struct Unit: WKTEntity {
    
    static let keyword = "UNIT"
    
    let name: String
    let conversionFactor: Double
    let authority: Authority?
}


struct Authority: WKTEntity {
    
    static let keyword = "AUTHORITY"
    
    let name: String
    let code: String
}


struct VertDatum: WKTEntity {
    
    static let keyword = "VERT_DATUM"
    
    let name: String
    let datumType: Double
    let authority: Authority?
}


struct Axis: WKTEntity {
    
    enum Direction: String, Decodable {
        case NORTH, SOUTH, EAST, WEST, UP, DOWN, OTHER
    }
    
    static let keyword = "AXIS"
    
    let name: String
    let direction: Direction
}


struct ToWGS84: WKTEntity {
    
    static let keyword = "TOWGS84"
    
    let dx, dy, dz, ex, ey, ez, ppm: Double
}


struct LocalDatum: WKTEntity {
    
    static let keyword = "LOCAL_DATUM"
    
    let name: String
    let datumType: Double
    let authority: Authority?
}


struct ParamMT: MathTransform {
    
    static let keyword = "PARAM_MT"
    
    let classificationName: String
    let parameters: [Parameter]?
}


struct ConcatMT: MathTransform {
    
    static let keyword = "CONCAT_MT"
    
    let mathTransform: Varied<MathTransform>
    let mathTransforms: [Varied<MathTransform>]?
}


struct InvMT: MathTransform {
    
    static let keyword = "INVERSE_MT"
    
    let mathTransform: Varied<MathTransform>
}


struct PassthroughMT: MathTransform {
    
    static let keyword = "PASSTHROUGH_MT"
    
    let integer: Int
    let mathTransform: Varied<MathTransform>
}



public class WKTDecoder: Decoder {
    
    enum Error: Swift.Error {
        case noObjectsToDecode(to: Any)
        case typeMismatchOnDecode(from: Any, to: Any)
        
        var localizedDescription: String {
            switch self {
            case .noObjectsToDecode(let type): return "No objects to decode to \(type)"
            case .typeMismatchOnDecode(let object, let type): return "Type mismatch on decode from \(object) to \(type)"
            }
        }
    }
    
    /// Forwards everything to the decoder ignoring the keys.
    private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        
        let decoder: WKTDecoder
        
        var codingPath: [CodingKey] {
            return []
        }
        
        var allKeys: [Key] {
            return []
        }
        
        func contains(_ key: Key) -> Bool {
            return true
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            return false
        }
        
        func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
            return try? decode(type, forKey: key)
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            return try decoder.decode(type)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return try decoder.unkeyedContainer()
        }
        
        func superDecoder() throws -> Decoder {
            return decoder
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            return decoder
        }
    }
    
    /// Forwards everything to the decoder while the same type.
    private struct UnkeyedContainer: UnkeyedDecodingContainer {
        
        let decoder: WKTDecoder
        
        private var elementType: Any.Type?
        
        init(decoder: WKTDecoder) {
            self.decoder = decoder
        }
        
        public var codingPath: [CodingKey] {
            return []
        }

        public var count: Int? {
            return nil
        }
        
        public var isAtEnd: Bool {
            guard let type = elementType else { return false }
            
            guard let object = decoder.objectQueue.first else { return true }
            
            if let type = type as? WKTEntity.Type, let object = object as? WKTSerialization.WKTObject {
                return type.keyword != object.keyword
            } else {
                return Swift.type(of: object) != type
            }
        }
        
        public var currentIndex: Int {
            return 0
        }
        
        public func decodeNil() -> Bool {
            return false
        }
        
        public mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            elementType = type
            return try decoder.decode(type)
        }
        
        public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }
        
        public func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return try decoder.unkeyedContainer()
        }
        
        public func superDecoder() throws -> Decoder {
            return decoder
        }
    }
    
    
    private var objectQueue = [Any]()
    
    public var codingPath: [CodingKey] {
        return []
    }
    
    public var userInfo: [CodingUserInfoKey : Any] {
        return [:]
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedContainer(decoder: self)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
    
    
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        
        guard let rootObject = try WKTSerialization.wktObjects(with: data).first else { throw Error.noObjectsToDecode(to: type) }
        
        func append(object: WKTSerialization.WKTObject) {
            objectQueue.append(WKTSerialization.WKTObject(keyword: object.keyword, parameters: []))
            for parameter in object.parameters {
                if let parameter = parameter as? WKTSerialization.WKTObject {
                    append(object: parameter)
                } else {
                    objectQueue.append(parameter)
                }
            }
        }
        append(object: rootObject)
        
        return try type.init(from: self)
    }
}


extension WKTDecoder: SingleValueDecodingContainer {
    
    public func decodeNil() -> Bool {
        return false
    }
    
    public func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        
        guard let object = objectQueue.first else { throw Error.noObjectsToDecode(to: type) }
        
        if let object = object as? T {
            objectQueue.removeFirst()
            return object
        }
        
        if let object = object as? WKTSerialization.WKTObject {
            if type is String.Type {
                objectQueue.removeFirst()
                return object.keyword as! T
            }
            if (type as? WKTEntity.Type)?.keyword == object.keyword {
                objectQueue.removeFirst()
                return try type.init(from: self)
            }
        }
        
        if !(type is WKTEntity.Type) {
            return try type.init(from: self)
        }
        
        throw Error.typeMismatchOnDecode(from: object, to: type)
    }
}



struct WKTSerialization {
    
    enum Error: Swift.Error {
        case unableInitString
        case objectsNotFound
        
        var localizedDescription: String {
            switch self {
            case .unableInitString: return "Unable to initialize a string with a given data"
            case .objectsNotFound: return "No objects found in a string"
            }
        }
    }
    
    
    enum BracketsType {
        case round
        case square
        
        var opening: Character {
            switch self {
            case .round: return "("
            case .square: return "["
            }
        }
        var closing: Character {
            switch self {
            case .round: return ")"
            case .square: return "]"
            }
        }
    }
    
    
    struct WKTObject: CustomStringConvertible {
        
        let keyword: String
        let parameters: [Any]
        
        var description: String {
            return keyword + parameters.description
        }
    }
    
    
    static func wktObjects(with data: Data, brackets: BracketsType = .square) throws -> [WKTObject] {
        
        guard let wkt = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? String(data: data, encoding: .macOSRoman) else { throw Error.unableInitString }
        
        func parse<S: StringProtocol>(_ string: S) -> [Any] {
            var result = [Any]()
            var startIndex = string.startIndex
            var index = startIndex
            while index < string.endIndex {
                switch string[index] {
                case "\"":
                    var isEvenQuote = false
                    let firstQuoteIndex = index
                    var lastQuoteIndex = index
                    loop: while index < string.index(before: string.endIndex) {
                        index = string.index(after: index)
                        switch string[index] {
                        case "\"":
                            isEvenQuote = !isEvenQuote
                            lastQuoteIndex = index
                            if string.index(after: index) == string.endIndex {
                                fallthrough
                            }
                        case ",", brackets.closing,
                             _ where string.index(after: index) == string.endIndex:
                            if isEvenQuote {
                                let text = String(string[string.index(after: firstQuoteIndex)..<lastQuoteIndex])
                                result.append(text)
                                break loop
                            }
                        default:
                            break
                        }
                    }
                    startIndex = string.index(after: index)
                case brackets.opening:
                    var isEvenQuote = true
                    var bracketCount = 1
                    let firstBracketIndex = index
                    loop: while index < string.index(before: string.endIndex) {
                        index = string.index(after: index)
                        switch string[index] {
                        case "\"":
                            isEvenQuote = !isEvenQuote
                        case brackets.opening where isEvenQuote:
                            bracketCount += 1
                        case brackets.closing where isEvenQuote:
                            bracketCount -= 1
                            if bracketCount == 0 {
                                let keyword = String(string[startIndex..<firstBracketIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                                let parameters = parse(string[string.index(after: firstBracketIndex)..<index])
                                result.append(WKTObject(keyword: keyword, parameters: parameters))
                                break loop
                            }
                        default:
                            break
                        }
                    }
                    startIndex = string.index(after: index)
                case ",", brackets.closing,
                     _ where string.index(after: index) == string.endIndex:
                    let endIndex = [",", brackets.closing].contains(string[index]) ? index : string.endIndex
                    let text = String(string[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if let value = Double(text) {
                        result.append(value)
                    }
                    else if !text.isEmpty {
                        result.append(text)
                    }
                    startIndex = string.index(after: index)
                default:
                    break
                }
                index = string.index(after: index)
            }
            return result
        }
        
        guard let wktObjects = (parse(wkt).filter { $0 is WKTObject }) as? [WKTObject], !wktObjects.isEmpty else { throw Error.objectsNotFound }
        
        return wktObjects
    }
}
