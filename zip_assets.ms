import "lib/zip"
zip = globals["lib/zip"]

z = zip.ZipWriter.make

// Function to recursively add files
addDirectory = function(dirPath)
	print "Processing: " + dirPath

	// Ensure directory entry exists in zip (optional, but good practice)
	// If dirPath is "assets", we want "assets/" in zip
	if dirPath[-1] != "/" then zipPath = dirPath + "/" else zipPath = dirPath
	z.add zipPath, ""

	for child in file.children(dirPath)
		if child == ".DS_Store" then continue // Skip system files

		fullPath = dirPath + "/" + child
		info = file.info(fullPath)

		if info == null then
			print "Warning: Could not get info for " + fullPath
			continue
		end if

		if info.isDirectory then
			addDirectory fullPath
		else
			print "  Adding: " + child
			data = file.loadRaw(fullPath)
			if data == null then
				print "  Error: Could not load " + fullPath
			else
				z.add fullPath, data
			end if
		end if
	end for
end function

print "Creating assets.zip..."
addDirectory "assets"

z.save "assets.zip"

if file.exists("assets.zip") then
	print "Success! assets.zip created."
	print "Size: " + file.info("assets.zip").size + " bytes"
else
	print "Error: Failed to create assets.zip"
end if
