# ZIP Module Walkthrough
I have implemented a basic ZIP module for Mini Micro using the RawData class. This module allows you to create ZIP archives containing files with "Store" compression (no compression).

## Changes
* lib/zip.ms
    * Implemented ZipWriter class.
    * Added crc32 calculation using a precomputed table.
    * Added RawData helper methods for writing little-endian integers.
    * Implemented add method to add files to the archive.
    * Implemented save method to write the ZIP file to disk using file.saveRaw (much faster than string conversion).
    * Updated RawData usage to use setByte and byte methods for compatibility with file.saveRaw.
    * Fixed CRC32 calculation to use bitXor and bitAnd intrinsics (replacing ^ which is power operator).
    * Added MS-DOS timestamp encoding and External File Attributes (0x20) for better compatibility.

## Verification Results
### Automated Verification
I created a verification script test_zip.ms that generates a test.zip file. Running unzip -l test.zip confirmed the archive structure:

```bash
Archive:  test.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
       12  00-00-1980 00:00   hello.txt
       20  00-00-1980 00:00   test.txt
---------                     -------
       32                     2 files
```

### Usage Example
You can use the test_zip.ms script as a reference:

```ms
import "zip"
z = zip.ZipWriter.make
z.add "hello.txt", "Hello World!"
z.save "output.zip"
```