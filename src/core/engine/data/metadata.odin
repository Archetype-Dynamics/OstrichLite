package data

import lib "../../../library"
import "core:crypto"
import "core:crypto/hash"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file contains all the logic for interacting with
            records within the OstrichLite engine.
*********************************************************/


//Sets the collections file format version(FFV)
@(require_results)
set_file_format_version :: proc() -> (string, bool) {
	ffvData, success := get_file_format_version()
	defer delete(ffvData)
	if !success{
	    return "", false
	}
	return strings.clone(string(ffvData)), true
}

//Gets the file format version from the file format version file
@(require_results)
get_file_format_version :: proc() -> ([]u8, bool) {
	using lib
	using fmt

	success := false

	versionFilePath := tprintf("%s%s",ROOT_PATH, "version")
	defer delete(versionFilePath)

	file, openSuccess := os.open(versionFilePath)
	if openSuccess != 0 {
	    make_new_err(.CANNOT_OPEN_FILE, get_caller_location())
		return []u8{}, success
	}

	data, readError := os.read_entire_file(versionFilePath)
	if readError == false {
		make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return []u8{}, success
	}else{
	    success  = true
	}

	os.close(file)
	return data, success
}

//this will get the size of the file and then subtract the size of the metadata header
//then return the difference
@(require_results)
subtract_metadata_size_from_collection :: proc(collection: ^lib.Collection) -> (int, bool) {
	using lib

	success:= false

	collectionPath:= concat_standard_collection_name(collection.name)
	defer delete(collectionPath)

	collectionInfo:= get_file_info(collectionPath)
	totalSize := int(collectionInfo.size)

	data, readSuccess := os.read_entire_file(collectionPath)
	defer delete(data)
	if !readSuccess {
	    make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return -1, success
	}

	content := string(data)
	defer delete(content)

	// Find metadata end marker
	metadataEnd := strings.index(content, METADATA_END)
	if metadataEnd == -1 {
		return -2, success
	}else{
	    success = true
	}

	// Add length of end marker to get total metadata size
	metadataSize := metadataEnd + len(METADATA_END)

	// Return actual content size (total - metadata) and metadata size
	return  metadataSize, success
}

// Calculates a SHA-256 checksum for .ostrichdb files based on file content
@(require_results)
generate_checksum :: proc(collection: ^lib.Collection) -> string {
	using lib
	using fmt
	using strings


	collectionPath:= concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)
	if !readSuccess {
		make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return ""
	}

	content := string(data)
	defer delete(content)

	//find metadata section boundaries
	metadataStart := index(content, METADATA_START)
	metadataEnd := index(content, METADATA_END)

	if metadataEnd == -1 {
		// For new files, generate unique initial checksum
		uniqueContent := tprintf("%s_%v", collection.name, time.now())
		hashedContent := hash.hash_string(hash.Algorithm.SHA256, uniqueContent)
		return clone(tprintf("%x", hashedContent))
	}

	//extract content minus metadata header
	actualContent := content[metadataEnd + len(METADATA_END):]

	//hash sub metadata header content
	hashedContent := hash.hash_string(hash.Algorithm.SHA256, actualContent)

	//format hash so that its fucking readable...
	splitComma := split(tprintf("%x", hashedContent), ",")
	joinedSplit := join(splitComma, "")
	trimRBracket := trim(joinedSplit, "]")
	trimLBRacket := trim(trimRBracket, "[")
	checksumString, _ := strings.replace(trimLBRacket, " ", "", -1)

	delete(splitComma)
	delete(joinedSplit)
	delete(trimRBracket)
	delete(trimLBRacket)


	return clone(checksumString)
}

//!Only used when to append the metadata template upon .ostrichdb file creation NOT modification
//this appends the metadata header to the file as well as sets the time of creation
@(require_results)
append_metadata_header_to_collection :: proc(collection: ^lib.Collection) -> bool {
	using lib
	using strings

	success:= false

	collectionPath:= concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)
	if !readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return success
	}

	if has_prefix(string(data), METADATA_START) { //metadata header already found
		return success
	}

	file, openSuccess := os.open(collectionPath, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(file)
	if openSuccess != 0{
        make_new_err(.CANNOT_OPEN_FILE, get_caller_location())
        return success
	}

	writeSuccess := write_to_file(collectionPath,transmute([]u8)concatenate(METADATA_HEADER),get_caller_location())
	if !writeSuccess {
        make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
	}else{
	    success= true
	}

	return success
}


// Sets the passed in metadata field with an explicit value that is defined within this procedure
// 0 = Encryption state, 1 = File Format Version, 2 = Permission, 3 = Date of Creation, 4 = Date Last Modified, 5 = File Size, 6 = Checksum
explicitly_assign_metadata_value :: proc(collection:^lib.Collection, field: lib.MetadataField, value: string = "") -> bool {
	using lib
	using fmt
	using strings

	success:= false

	collectionPath:= concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)
	if !readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return success
	}

	lines := split(string(data), "\n")
	defer delete(lines)

	//not doing anything with h,m,s yet but its there if needed
	currentDate, h, m, s := get_date_and_time() // sets the files date of creation(FDOC) or file date last modified(FDLM)
	fileInfo := get_file_info(collectionPath)
	fileSize := fileInfo.size

	found := false
	for line, i in lines {
		switch field {
		case .ENCRYPTION_STATE:
			if has_prefix(line, "# Encryption State:") {
				if value != "" {
					lines[i] = fmt.tprintf("# Encryption State: %s", value)
				} else {
					lines[i] = fmt.tprintf("# Encryption State: %d", 0 ) // Default to 0 if no value provided
				}
				found = true
			}
			break
		case .FILE_FORMAT_VERSION:
			if has_prefix(line, "# File Format Version:") {
				// lines[i] = fmt.tprintf("# File Format Version: %s", set_ffv()) //Todo: need to figure out how to deal with ffv
				found = true
			}
			break
		case .PERMISSION:
			if has_prefix(line, "# Permission:") {
				lines[i] = tprintf("# Permission: %s", "Read-Write")
				found = true
			}
		case .DATE_CREATION:
			if has_prefix(line, "# Date of Creation:") {
				lines[i] = tprintf("# Date of Creation: %s", currentDate)
				found = true
			}
			break
		case .DATE_MODIFIED:
			if has_prefix(line, "# Date Last Modified:") {
				lines[i] = tprintf("# Date Last Modified: %s", currentDate)
				found = true
			}
			break
		case .FILE_SIZE:
			if has_prefix(line, "# File Size:") {
				actualSize, _ := subtract_metadata_size_from_collection(collection)
				if actualSize != -1 {
					lines[i] = tprintf("# File Size: %d Bytes", actualSize)
					found = true
				}
			}
			break
		case .CHECKSUM:
			if has_prefix(line, "# Checksum:") {
				lines[i] = tprintf("# Checksum: %s", generate_checksum(collection))
				found = true
			}
		}
		if found {
			break
		}
	}

	if !found {
		return success
	}

	newContent := strings.join(lines, "\n")
	defer delete(newContent)

	writeSuccess := write_to_file(collectionPath, transmute([]byte)newContent, get_caller_location())
	if !writeSuccess{
        make_new_err(.CANNOT_WRITE_TO_FILE,get_caller_location())
        return success
	}else{
	    success = true
	}

	return success
}


//returns the string value of the passed metadata field
// colType: 1 = public(standard), 2 = history, 3 = config, 4 = ids
@(require_results)
get_metadata_field_value :: proc(collection:^lib.Collection, field: string,colType: lib.CollectionType, d: ..[]byte) -> (string, bool) {
	using lib
	using fmt

	success:= false

	collectionPath := concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)
	if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return "", success
	}

	if len(d) != 0{
	    if len(d[0])> 0{ //if there is a passed in d(data) arg then data is equal to that
            data= d[0]
		}
	}

	lines := strings.split(string(data), "\n")
	defer delete(lines)

	// Check if the metadata header is present
	if !strings.has_prefix(lines[0], "@@@@@@@@@@@@@@@TOP") {
		return "", success
	}

	// Find the end of metadata section
	metadataEndIndex := -1
	for i in 0 ..< len(lines) {
		if strings.has_prefix(lines[i], "@@@@@@@@@@@@@@@BTM") {
			metadataEndIndex = i
			break
		}
	}

	if metadataEndIndex == -1 {
		return "", success
	}

	// Verify the header has the correct number of lines
	expectedLines := 9 // 7 metadata fields + start and end markers
	if metadataEndIndex != expectedLines - 1 {
		return "", success
	}

	for i in 1 ..< 6 {
		if strings.has_prefix(lines[i], field) {
			val := strings.split(lines[i], ": ")
			return strings.clone(val[1]), true
		}
	}
	return "", success
}


//Similar to the explicitly_assign_metadata_value but updates a fields value the passed in newValue
//Currently only supports the following metadata fields:
//ENCRYPTION STATE
//PERMSSION
@(require_results)
update_metadata_value :: proc(collection:^lib.Collection, newValue: string,field: lib.MetadataField,colType: lib.CollectionType, username:..string) -> bool {
	using lib
	using strings

	success:= false

	collectionPath:= concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath,get_caller_location())
	defer delete(data)
	if !readSuccess {
	   make_new_err(.CANNOT_OPEN_FILE,get_caller_location())
		return success
	}

	lines := strings.split(string(data), "\n")
	defer delete(lines)

	fieldFound := false
	for line, i in lines {
		#partial switch(field) {
		case .ENCRYPTION_STATE:
		if strings.has_prefix(line, "# Encryption State:") {
			lines[i] = fmt.tprintf("# Encryption State: %s", newValue)
			fieldFound = true
		break
		}
		case .PERMISSION:
			if strings.has_prefix(line, "# Permission:") {
				lines[i] = fmt.tprintf("# Permission: %s", newValue)
				fieldFound = true
			}
			break
		}
	}

	if !fieldFound {
		return success
	}

	newContent := strings.join(lines, "\n")
	defer delete(newContent)

	writeSuccess := write_to_file(collectionPath, transmute([]byte)newContent, get_caller_location())
	if !writeSuccess{
	    make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
		return success
	}else{
        success = true
	}

	return success
}


//Assigns all neccesary metadata field values after a collection has been made
init_metadate_in_new_collection :: proc(collection: ^lib.Collection) {
    explicitly_assign_metadata_value(collection, .ENCRYPTION_STATE)
	explicitly_assign_metadata_value(collection, .FILE_FORMAT_VERSION)
	explicitly_assign_metadata_value(collection, .DATE_CREATION)
	explicitly_assign_metadata_value(collection, .DATE_MODIFIED)
	explicitly_assign_metadata_value(collection, .FILE_SIZE)
	explicitly_assign_metadata_value(collection, .CHECKSUM)
}


//Used after most operations on a collection file to update metadata fields that need to be updated
update_metadata_fields_after_operation :: proc(collection: ^lib.Collection) {
	explicitly_assign_metadata_value(collection, .DATE_MODIFIED)
	explicitly_assign_metadata_value(collection, .FILE_FORMAT_VERSION)
	explicitly_assign_metadata_value(collection, .FILE_SIZE)
	explicitly_assign_metadata_value(collection, .CHECKSUM)
}