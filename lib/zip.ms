// Very Basic ZIP archive creation module
// Author: RedSpark
// https://miniscript.org/wiki/RawData

// CRC32 Implementation
// CRC32 Implementation
crcTable = []
poly = 3988292384 // 0xEDB88320
for i in range(0, 255)
	c = i
	for k in range(0, 7)
		if c % 2 == 1 then
			c = bitXor(poly, floor(c / 2))
		else
			c = floor(c / 2)
		end if
	end for
	crcTable.push c
end for

crc32 = function(data)
	crc = 4294967295 // 0xFFFFFFFF
	if data.len == 0 then return 0
	if data isa string then
		for i in range(0, data.len - 1)
			idx = bitAnd(bitXor(crc, data[i].code), 255)
			term1 = floor(crc / 256)
			term2 = crcTable[idx]
			crc = bitXor(term1, term2)
			if crc < 0 then crc += 4294967296
		end for
	else if data isa RawData then
		for i in range(0, data.len - 1)
			idx = bitAnd(bitXor(crc, data.byte(i)), 255)
			term1 = floor(crc / 256)
			term2 = crcTable[idx]
			crc = bitXor(term1, term2)
			if crc < 0 then crc += 4294967296
		end for
	end if
	return bitXor(crc, 4294967295)
end function

// Helper to write little-endian integer to RawData
// Helper to write little-endian integer to RawData
RawData.writeLE = function(offset, value, bytes)
	if value < 0 then value += 4294967296
	for i in range(0, bytes - 1)
		self.setByte offset + i, value % 256
		value = floor(value / 256)
	end for
end function

// Helper to append RawData to another RawData
RawData.append = function(otherData)
	oldLen = self.len
	if otherData.len == 0 then return 
	self.resize oldLen + otherData.len
	for i in range(0, otherData.len - 1)
		self.setByte oldLen + i, otherData.byte(i)
	end for
end function

// Helper to append string as bytes
RawData.appendString = function(str)
	oldLen = self.len
	if str.len == 0 then return 
	self.resize oldLen + str.len
	for i in range(0, str.len - 1)
		self.setByte oldLen + i, str[i].code
	end for
end function

ZipWriter = {}
ZipWriter.data = null // RawData holding the zip content
ZipWriter.files = null // List of file entries for Central Directory

ZipWriter.make = function
	z = new ZipWriter
	z.data = new RawData
	z.files = []
	return z
end function

ZipWriter.add = function(filename, content)
	if content isa string then
		// Convert string to RawData if needed, or just use it directly for CRC/Size
		// For simplicity, let's treat it as bytes
		size = content.len
		crc = crc32(content)
	else if content isa RawData then
		size = content.len
		crc = crc32(content)
	else
		print "Error: Unsupported content type for " + filename
		return 
	end if

	offset = self.data.len

	// Local File Header
	header = new RawData
	header.resize 30
	header.writeLE 0, 67324752, 4 // Signature 0x04034b50
	header.writeLE 4, 20, 2 // Version needed (2.0)
	header.writeLE 6, 0, 2 // Flags
	header.writeLE 8, 0, 2 // Compression method (0 = Store)
	header.writeLE 10, 24576, 2 // Last mod time (12:00:00)
	header.writeLE 12, 22390, 2 // Last mod date (2023-11-22)
	header.writeLE 14, crc, 4 // CRC-32
	header.writeLE 18, size, 4 // Compressed size
	header.writeLE 22, size, 4 // Uncompressed size
	header.writeLE 26, filename.len, 2 // Filename length
	header.writeLE 28, 0, 2 // Extra field length

	self.data.append header
	self.data.appendString filename

	if content isa string then
		self.data.appendString content
	else
		self.data.append content
	end if

	// Record entry for Central Directory
	entry = {}
	entry.filename = filename
	entry.size = size
	entry.crc = crc
	entry.offset = offset
	self.files.push entry
end function

ZipWriter.save = function(path)
	cdOffset = self.data.len

	// Write Central Directory
	for f in self.files
		cdHeader = new RawData
		cdHeader.resize 46
		cdHeader.writeLE 0, 33639248, 4 // Signature 0x02014b50
		cdHeader.writeLE 4, 20, 2 // Version made by
		cdHeader.writeLE 6, 20, 2 // Version needed
		cdHeader.writeLE 8, 0, 2 // Flags
		cdHeader.writeLE 10, 0, 2 // Compression method
		cdHeader.writeLE 12, 24576, 2 // Time
		cdHeader.writeLE 14, 22390, 2 // Date
		cdHeader.writeLE 16, f.crc, 4 // CRC32
		cdHeader.writeLE 20, f.size, 4 // Compressed size
		cdHeader.writeLE 24, f.size, 4 // Uncompressed size
		cdHeader.writeLE 28, f.filename.len, 2 // Filename length
		cdHeader.writeLE 30, 0, 2 // Extra field length
		cdHeader.writeLE 32, 0, 2 // File comment length
		cdHeader.writeLE 34, 0, 2 // Disk number start
		cdHeader.writeLE 36, 0, 2 // Internal file attributes
		// External file attributes
		extAttr = 32 // 0x20 Archive
		if f.filename.len > 0 and f.filename[-1] == "/" then extAttr = 16 // 0x10 Directory
		cdHeader.writeLE 38, extAttr, 4
		cdHeader.writeLE 42, f.offset, 4 // Relative offset of local header

		self.data.append cdHeader
		self.data.appendString f.filename
	end for

	cdSize = self.data.len - cdOffset

	// End of Central Directory Record
	eocd = new RawData
	eocd.resize 22
	eocd.writeLE 0, 101010256, 4 // Signature 0x06054b50
	eocd.writeLE 4, 0, 2 // Number of this disk
	eocd.writeLE 6, 0, 2 // Disk where CD starts
	eocd.writeLE 8, self.files.len, 2 // Number of CD records on this disk
	eocd.writeLE 10, self.files.len, 2 // Total number of CD records
	eocd.writeLE 12, cdSize, 4 // Size of CD
	eocd.writeLE 16, cdOffset, 4 // Offset of CD
	eocd.writeLE 20, 0, 2 // Comment length

	self.data.append eocd

	// Write to file
	file.saveRaw path, self.data
end function

if locals == globals then
	print "Zip module loaded."
end if
