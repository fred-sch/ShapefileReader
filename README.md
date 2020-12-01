# ShapefileReader
__A shapefile reader in Swift__

__Description__

Reads data from files in [Shapefile](https://en.wikipedia.org/wiki/Shapefile) format.

__API Overview__

ShapefileReader is the only object you instantiate.

Internally, it builds the three following objects, depending on the available auxiliary files:
- `SHPReader` to read the shapes, ie the list of points
- `DBFReader` to read the data records associated with the shapes
- `SHXReader` to read the indices of the shapes, thus allowing direct access
- `PRJReader` to read the coordinate system and projection information

Most usages of `ShapefileReader` will remain like:

```swift
guard let sr = ShapefileReader(path: "g1g15.shp") else { assertionFailure() }

// iterate over both shapes and records
for (shape, record) in zip(sr.shp, sr.dbf!) {
    // record is [AnyObject]

    for points in shape {
        // draw polygon with [CGPoint]
        // or map to [CLLocationCoordinate2D] using sr.coordinateConverter()
    }
}
```

DBF API

```swift
// if dbf file exists
if let dbf = sr.dbf {
    // number of records
    let n = dbf.numberOfRecords
    
    // fields description
    print(dbf.fields)
    
    // iterate over records
    for r in dbf {
        // ...
    }
    
    // access a record by index
    print(dbf[1847])
}
```

    [[DeletionFlag, C, 1, 0], [GMDNR, N, 9, 0], [GMDNAME, C, 50, 0], [BZNR, N, 9, 0], [KTNR, N, 9, 0], [GRNR, N, 9, 0], [AREA_HA, N, 9, 0], [X_MIN, N, 9, 0], [X_MAX, N, 9, 0], [Y_MIN, N, 9, 0], [Y_MAX, N, 9, 0], [X_CNTR, N, 9, 0], [Y_CNTR, N, 9, 0], [Z_MIN, N, 9, 0], [Z_MAX, N, 9, 0], [Z_AVG, N, 9, 0], [Z_MED, N, 9, 0], [Z_CNTR, N, 9, 0]]  
    [5586, Lausanne, 2225, 22, 1, 4138, 534438, 544978, 150655, 161554, 538200, 152400, 371, 930, 670, 666, 585]

SHX API

```swift
// if index file exists
if let shx = sr.shx {
    // access a shape by index
    if let offset = shx.shapeOffsetAtIndex(2) {
    	if let (nextIndex, shape) = shp.shapeAtOffset(offset) {
	        // use shape   	
    	}
    }
}
```

or more simply

```swift
let shape = sr[2]
```

PRJ API

```swift
if let cs = sr.prj?.cs {
    // use CoordinateSystem information to convert CGPoint to CLLocationCoordinate2D
}
```
You can override sr.coordinateConverter() to support coordinate systems other than WGS84

__Implementation Details__

- shape points are CGPoint arrays
- record are arrays of Int, Double, Bool or String (no NSDate, no optionals)
- random access in files and enumerators are used each time it is possible
- most of time, code will ignore when files do not match the specs, feel free to open an issue and join the offending files in case of crash

__Tests and Drawing__

The package comes with a unit test target.

Also, it comes with a project that contains `BitmapCanvas` and its subclass `BitmapCanvasShapefile` which will generate the following PNG files.

<a href="Images/switzerland_altitude.png"><img src="Images/switzerland_altitude.png" width="890" alt="Switzerland Altitude" /></a>

<a href="Images/switzerland_zip.png"><img src="Images/switzerland_zip.png" width="890" alt="Switzerland ZIP Codes" /></a>

