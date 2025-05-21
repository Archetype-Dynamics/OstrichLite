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
@(require_results)
make_new_collection :: proc(name:string, type: lib.CollectionType) -> ^lib.Collection{
    using lib

    collection := new(lib.Collection)
    collection.name = name
    collection.type = type
    collection.numberOfClusters = 0
    collection.clusters = make([dynamic]Cluster, 0)

    return collection
}

//Creates a standard collection file
@(require_results)
create_collection_file :: proc(collection: ^lib.Collection) -> bool {
    using lib
    success:= false

    // Check if a collection of the passed in name already exists
   if check_if_collection_exists(collection){
       make_new_err(.COLLECTION_ALREADY_EXISTS, get_caller_location())
       return success
   }

    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    file, creationSuccess:= os.open(collectionPath, os.O_CREATE, 0o666)
	defer os.close(file)

    appendSuccess:= append_metadata_header_to_collection(collection)
    if !appendSuccess{
        return success
    }

	updateSuccess:=update_metadata_value(collection, "Read-Write",MetadataField.PERMISSION, .STANDARD_PUBLIC)
	if !updateSuccess{
	    return success
	}

	if creationSuccess != nil{
		make_new_err(.CANNOT_CREATE_COLLECTION, get_caller_location())
		return success
	}else{
	    success = true
	}

	init_metadate_in_new_collection(collection)

	return success
}

@(require_results)
erase_collection ::proc(collection: ^lib.Collection) -> bool{
   	using lib

    success:= false

    if !check_if_collection_exists(collection){
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

	collectionPath := concat_standard_collection_name(collection.name)
	defer delete(collectionPath)

	deleteSuccess := os.remove(collectionPath)
	if deleteSuccess != 0 {
        make_new_err(.CANNOT_DELETE_FILE, get_caller_location())
	}else {
        success = true
	}

	return success
}


//Renames the passed in collection.name to the new name
@(require_results)
rename_collection :: proc(collection: ^lib.Collection, newName:string) -> bool {
    using lib
    success := false

    //Check if a collection with the name that the user wants to rename does in fact check_if_collection_exists
    if !check_if_collection_exists(collection){
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

    //Now check if there is already a collection using the name "newName"
    newCollection:= make_new_collection(newName, .STANDARD_PUBLIC)
    defer free(newCollection)
    if check_if_collection_exists(newCollection){
        make_new_err(.COLLECTION_ALREADY_EXISTS, get_caller_location())
        return success
    }

	collectionPath := concat_standard_collection_name(collection.name)
	defer delete(collectionPath)

	renameSuccess := os.rename(collectionPath, newName)
	if renameSuccess{
	   success = true
	}

	delete(newName)
	return success
}

//reads and returns the body of the passed in collection
@(require_results)
fetch_collection :: proc(collection: ^lib.Collection) -> (string, bool) {
    using lib
    using strings

    success:= false
	fileStart := -1
	startingPoint := "BTM@@@@@@@@@@@@@@@"
	defer delete(startingPoint)

    if !check_if_collection_exists(collection){
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return "",success
    }

	collectionPath := concat_standard_collection_name(collection.name)
	defer delete(collectionPath)

	data, readSuccess := os.read_entire_file(collectionPath)
	defer delete(data)

	if !readSuccess {
		make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return "",success
	}

	lines := split(string(data), "\n")
	defer delete(lines)

	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], startingPoint) {
			fileStart = i + 1 // Start from the next line after the header
			break
		}
	}

	if fileStart == -1 || fileStart >= len(lines) {
	    //No data found
		return "",success
	}else{
        success = true
	}

	collectionContent := strings.join(lines[fileStart:], "\n")
	return  strings.clone(collectionContent), success
}

//deletes all data from a collection while retaining the metadat header
@(require_results)
purge_collection :: proc(collection: ^lib.Collection) -> bool {
	using lib
	using strings

	success:= false

	if !check_if_collection_exists(collection){
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

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
	    return success
	}

	// Get the metadata header
	headerEndIndex += len(METADATA_END) + 1
	metadataHeader := content[:headerEndIndex]
	defer delete(metadataHeader)

	// Write back only the header
	writeSuccess := write_to_file(collectionPath, transmute([]byte)metadataHeader, get_caller_location())
	if !writeSuccess {
        make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
		return success
	}else{
	    success = true
	}

	return success
}

//Reads over all standard collections, appends their names and returns them
//Dont forget to free the memory in the calling procedure
@(require_results)
get_all_collection_names :: proc() -> [dynamic]string{
    using lib

    collectionArray:= make([dynamic]string, 0)
    standardCollectionDir, openDirError :=os.open(STANDARD_COLLECTION_PATH)
    collections, readDirError:= os.read_dir(standardCollectionDir, 1)
    if readDirError!=nil{
        make_new_err(.CANNOT_READ_DIRECTORY, get_caller_location())
        return collectionArray
    }

    for collection in collections{
        append(&collectionArray, collection.name)
    }

    return collectionArray
}

//See if the passed in collection exists in the path
@(require_results)
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
@(require_results)
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
@(require_results)
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
	defer delete(invalidChars)

	for c := 0; c < len(collection.name); c += 1 {
		if strings.contains_any(collection.name, invalidChars) {
			return false
		}
	}

	return true
}
