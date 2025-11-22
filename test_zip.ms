import "zip"

print "Testing ZipWriter..."
z = zip.ZipWriter.make
z.add "hello.txt", "Hello World!"
z.add "test.txt", "This is a test file."

print "Saving to test.zip..."
z.save "test.zip"

if file.exists("test.zip") then
	print "Success: test.zip created."
	print "Size: " + file.info("test.zip").size + " bytes"
else
	print "Error: test.zip not created."
end if
