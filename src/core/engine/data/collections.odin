package data

import lib "../../../library"
import "core:fmt"
import "core:strings"
import "core:os"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file contains all the logic for interacting with
            collections within the OstrichLite engine.
*********************************************************/

//creates a new lib.Collection
make_new_collection :: proc(name:string, type:lib.CollectionType) -> ^lib.Collection{
    using lib

    collection := new(lib.Collection)
    collection.name = name
    collection.type = type
    collection.numberOfClusters = 0
    collection.clusters = make([dynamic]Cluster, 0)

    return collection
}

//Creates a standard collection file
create_collection_file :: proc(collection: ^lib.Collection) -> bool {
    using lib
    success:= false

    // Check if a collection of the passed in name
   if  !check_if_collection_exists(collection){
       return success
   }

    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    file, creationSuccess:= os.open(collectionPath, os.O_CREATE, 0o666)
	defer os.close(file)
    //Todo: need to append metadata header here
    // metadata.APPEND_METADATA_HEADER_TO_COLLECTION(collectionPath)
	// metadata.UPDATE_METADATA_MEMBER_VALUE(fn, "Read-Write",MetadataField.PERMISSION, colType)

	if creationSuccess != nil{
		make_new_err(.CANNOT_CREATE_COLLECTION, get_caller_location())
		return success
	}else{
	    success = true
	}

	//Todo: need to update metadata header field values
	// metadata.INIT_METADATA_IN_NEW_COLLECTION(collectionPath)

	return success
}

//Renames the passed in collection.name to the new name
rename_collection :: proc(collection: ^lib.Collection, newName:string) -> bool {
    using lib
    success := false

    // Check if a collection of the passed in name
   if  !check_if_collection_exists(collection){
       return success
   }

	collectionPath := concat_standard_collection_name(collection.name)
	renameSuccess := os.rename(collectionPath, newName)
	if renameSuccess{
	   success = true
	}

	return success
}

//reads and returns the body of the passed in collection
fetch_collection :: proc(collection: ^lib.Collection) -> (bool,string) {
    using lib

    success:= false
	fileStart := -1
	startingPoint := "BTM@@@@@@@@@@@@@@@"

    // Check if a collection of the passed in name
   if  !check_if_collection_exists(collection){
       return success, ""
   }

	collectionPath := concat_standard_collection_name(collection.name)

	data, readSuccess := os.read_entire_file(collectionPath)
	defer delete(data)

	if !readSuccess {
		make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return success, ""
	}

	content := string(data)
	defer delete(content
	)
	lines := strings.split(content, "\n")
	defer delete(lines)

	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], startingPoint) {
			fileStart = i + 1 // Start from the next line after the header
			break
		}
	}

	if fileStart == -1 || fileStart >= len(lines) {
	    //No data found
		return success, ""
	}

	collectionContent := strings.join(lines[fileStart:], "\n")
	return true, strings.clone(collectionContent)
}

//deletes all data from a collection while retaining the metadat header
purge_collection :: proc(collection: ^lib.Collection) -> bool {
	using lib

	success:= false

	collectionPath := concat_standard_collection_name(collection.name)

	data, readSuccess := os.read_entire_file(collectionPath)
	defer delete(data)

	if !readSuccess {
		make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return success
	}

	content := string(data)
	defer delete(content)

	// Find the end of the metadata header
	headerEndIndex := strings.index(content, METADATA_END)
	if headerEndIndex == -1 {
	    errorLocation:= get_caller_location()
	    log_err("Error: Error findining metadata header end index", errorLocation)
	    return success
	}

	// Get the metadata header
	headerEndIndex += len(METADATA_END) + 1
	metadataHeader := content[:headerEndIndex]

	// Write back only the header
	writeSuccess := write_to_file(collectionPath, transmute([]byte)metadataHeader, get_caller_location())
	if !writeSuccess {
	    errorLocation:= get_caller_location()
		error:= new_err(.CANNOT_WRITE_TO_FILE, ErrorMessage[.CANNOT_WRITE_TO_FILE], errorLocation)
		log_err("Error writing purged collection file", errorLocation)
		return success
	}else{success = true}

	return success
}

//Reads over all standard collections, appends their names and returns them
//Dont forget to free the memory in the calling procedure
get_all_collection_names :: proc() -> [dynamic]string{
    using lib

    collectionArray:= make([dynamic]string, 0)
    standardCollectionDir, openDirError :=os.open(STANDARD_COLLECTION_PATH)

    collections, readDirError:= os.read_dir(standardCollectionDir, 1)
    for collection in collections{
        append(&collectionArray, collection.name)
    }

    return collectionArray
}

//See if the passed in collection exists in the path
check_if_collection_exists :: proc(collection: ^lib.Collection) -> bool {
    using lib

    exists:= false

	collectionPath, openSuccess := os.open(STANDARD_COLLECTION_PATH)
	files, readSuccess := os.read_dir(collectionPath, -1)

	for file in files {
		if file.name == fmt.tprintf("%s%s", collection.name, OST_EXT) {
		    exists = true
		}
	}

	return exists
}

//gets the number of  collections
get_collection_count :: proc() -> int {
	using lib

	collectionCount:= 0

	collectionDir, openError := os.open(STANDARD_COLLECTION_PATH)
	defer os.close(collectionDir)

	collections, dirReadSuccess := os.read_dir(collectionDir, -1)
	for collection in collections  {
		if strings.contains(collection.name, OST_EXT) {
		    collectionCount+=1
		}
	}

	return collectionCount
}

//Checks if the passed in collection.name is valid
validate_collection_name :: proc(collection: ^lib.Collection) -> bool {
	using lib

	//CHECK#1: check collection name length
	nameAsBytes := transmute([]byte)collection.name
	if len(nameAsBytes) > MAX_COLLECTION_NAME_LENGTH {
		return false
	}

	//CHECK#2: check if the file already exists
	collectionExists :=check_if_collection_exists(collection)
	if collectionExists {
	    return false
	}

	//CHECK#3: check if the name has special chars
	invalidChars := "[]{}()<>;:.,?/\\|`~!@#$%^&*+="
	for c := 0; c < len(collection.name); c += 1 {
		if strings.contains_any(collection.name, invalidChars) {
			return false
		}
	}

	return true
}
