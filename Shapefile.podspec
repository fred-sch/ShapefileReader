Pod::Spec.new do |s|

  s.name         = "ShapefileReader"
  s.version      = "0.1.0"
  s.summary      = "Reads data from files in Shapefile format."

  s.description  = <<-DESC
ShapefileReader is the only object you instantiate.
Internally, it builds the three following objects, depending on the available auxiliary files:
- SHPReader to read the shapes, ie the list of points;
- DBFReader to read the data records associated with the shapes;
- SHXReader to read the indices of the shapes, thus allowing direct access;
- PRJReader to read the coordinate system and projection information.
                   DESC

  s.homepage     = "https://github.com/DnV1eX/ShapefileReader"

  s.license      = "MIT"

  s.authors      = { "Nicolas Seriot" => "nicolas.seriot@swissquote.ch", "Alexey Demin" => "dnv1ex@yahoo.com" }

  s.swift_version = "4.1"

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.12"

  s.source       = { :git => "https://github.com/DnV1eX/ShapefileReader.git", :tag => "#{s.version}" }

  s.source_files  = "Shapefile/Shapefile.swift", "vendor/BinUtils.swift", "vendor/CoordinateSystem.swift"

end
