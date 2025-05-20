package data

import lib "../../../library"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file contains all the logic for interacting with
            records within the OstrichLite engine.
*********************************************************/

// Creates a new lib.cluster, assigns its members with the passed in args, returns pointer to new lib.Record
make_new_record :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, recordName:string) -> ^lib.Record{
    using lib
    using fmt

    record:= new(Record)
    record.grandparent = collection^
    record.parent = cluster^
    record.id = 0
    record.name= recordName
    record.type = .INVALID
    record.value = ""

    return record
}

//Appends the physcal recode line to the passed in cluster within the passed in collection
create_record_within_cluster :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> bool{
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return success
    }

    recordAlreadyExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if recordAlreadyExists{
        make_new_err(.RECORD_ALREADY_EXISTS_IN_CLUSTER, get_caller_location())
        return success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    data, readSuccess:= read_file(collectionPath, get_caller_location())

    if !readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
    }

	lines := split(string(data), "\n")
	defer delete(lines)

	clusterStart := -1
	closingBrace := -1

	// Find the cluster and its closing brace
	for i := 0; i < len(lines); i += 1 {
		if contains(lines[i], cluster.name) {
			clusterStart = i
		}
		if clusterStart != -1 && contains(lines[i], "}") {
			closingBrace = i
			break
		}
	}

	//check if a record with the desired name already exists within the specified cluster
	recordExists := check_if_record_exists_in_cluster(collection, cluster, record)
	if recordExists {
	    make_new_err(.RECORD_ALREADY_EXISTS_IN_CLUSTER, get_caller_location())
		return success
	}

	//if the cluster is not found or the structure is invalid, return
	if clusterStart == -1 || closingBrace == -1 {
        make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
		return success
	}

	// construct the new record line
	newRecordLine := tprintf("\t%s :%s: %s", record.name, record.type, record.value)

	// Insert the new line and adjust the closing brace
	oldContent := make([dynamic]string, len(lines) + 1)
	defer delete(oldContent)

	copy(oldContent[:closingBrace], lines[:closingBrace])
	oldContent[closingBrace] = newRecordLine
	oldContent[closingBrace + 1] = "},"
	if closingBrace + 1 < len(lines) {
		copy(oldContent[closingBrace + 2:], lines[closingBrace + 1:])
	}
	newContent := join(oldContent[:], "\n")

	writeSuccess := write_to_file(collectionPath, transmute([]byte)newContent, get_caller_location())
	if !writeSuccess {
	    make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
		return success
	} else{
	    success = true
	}

    return success
}


//Reads over the passed in collection and the passed in cluster for the record. renames the record.name with the newName arg
rename_reocord :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, oldRecord: ^lib.Record, newName:string) -> bool {
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, oldRecord)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return success
    }

	newRecord:= make_new_record(collection, cluster, newName)
	defer free(newRecord)

	//If there is already a record with the desired new name throw error
	recordExistsInCluster:=check_if_record_exists_in_cluster(collection,cluster,newRecord)
	if recordExistsInCluster{
        make_new_err(.RECORD_ALREADY_EXISTS_IN_CLUSTER, get_caller_location())
        return success
	}

	collectionPath := concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)

	if !readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
	    return success
	}

	clusterBlocks := split(string(data), "},")
	defer delete(clusterBlocks)

	newContent := make([dynamic]u8)
	defer delete(newContent)

	recordFound := false

		for c in clusterBlocks {
			c := trim_space(c)
			if contains(c, tprintf("cluster_name :identifier: %s", cluster.name)) {
				// Found the correct cluster, now look for the record to rename
				lines := split(c, "\n")
				newCluster := make([dynamic]u8)
				defer delete(newCluster)

			for line in lines {
				trimmedLine := trim_space(line)
				if has_prefix(trimmedLine, tprintf("%s :", oldRecord.name)) {
					// Found the record to rename
					recordFound = true
					newLine, _:= replace(trimmedLine,tprintf("%s :", oldRecord.name),tprintf("%s :", newRecord.name),1,)
					append(&newCluster, "\t")
					append(&newCluster, ..transmute([]u8)newLine)
					append(&newCluster, "\n")
				} else if len(trimmedLine) > 0 {
					// Keep other lines unchanged
					append(&newCluster, ..transmute([]u8)line)
					append(&newCluster, "\n")
				}
			}

			// Add the modified cluster to the new content
			append(&newContent, ..newCluster[:])
			append(&newContent, "}")
			append(&newContent, ",\n\n")
		} else if len(c) > 0 {
			// Keep other clusters unchanged
			append(&newContent, ..transmute([]u8)c)
			append(&newContent, "\n}")
			append(&newContent, ",\n\n")
		}
	}

	if !recordFound {
		make_new_err(.CANNOT_FIND_RECORD, get_caller_location())
		return success
	}

	// write new content to file
	writeSuccess := os.write_entire_file(collectionPath, newContent[:])
	if !writeSuccess{
        make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
	}else{
	    success = true
	}

	return success
}
//finds a the passed in record, and physically updates its data type. keeps its value which will eventually need to be changed
update_record_data_type :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record, newType: string) -> bool {
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)
	if !readSuccess {
	    make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return success
	}

	lines := split(string(data), "\n")
	defer delete(lines)

	newLines := make([dynamic]string)
	defer delete(newLines)

	inTargetCluster := false
	recordUpdated := false

	// Find the cluster and update the record
	for line in lines {
		trimmedLine := trim_space(line)

		if trimmedLine == "{" {
			inTargetCluster = false
		}

		if contains(trimmedLine, tprintf("cluster_name :identifier: %s", cluster.name)) {
			inTargetCluster = true
		}

		if inTargetCluster && contains(trimmedLine, tprintf("%s :", record.name)) {
			// Keep the original indentation
			leadingWhitespace := split(line, record.name)[0]
			// Create new line with updated type
			newLine := tprintf("%s%s :%s: %s", leadingWhitespace, record.name, newType, record.value)
			append(&newLines, newLine)
			recordUpdated = true
		} else {
			append(&newLines, line)
		}

		if inTargetCluster && trimmedLine == "}," {
			inTargetCluster = false
		}
	}

	if !recordUpdated {
		make_new_err(.CANNOT_UPDATE_RECORD, get_caller_location())
		return success
	}

	// Write the updated content back to file
	newContent := join(newLines[:], "\n")
	writeSuccess := write_to_file(collectionPath, transmute([]byte)newContent, get_caller_location())
	if !writeSuccess{
	    make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
	    return success
	}else{
	    success = true
	}

	return success
}


//Used to replace a records current value with the passed in newValue
update_record_value :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record, newValue:any) -> bool{
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)

    lines:= split(string(data), "\n")
    defer delete(lines)

    inTargetCluster := false
	recordUpdated := false

	//First look and find the record in the cluster
	for line, i in lines {
		trimmedLine := trim_space(line)

		if trimmedLine == "{" {
			inTargetCluster = false
		}

		if contains(trimmedLine, "cluster_name :identifier:") {
			clusterNameParts := split(trimmedLine, ":")
			if len(clusterNameParts) >= 3 {
				currentClusterName := trim_space(clusterNameParts[2])
				if to_upper(currentClusterName) == to_upper(cluster.name) {
					inTargetCluster = true
				}
			}
		}

		// if in the target cluster, find the record and update it
		if inTargetCluster && contains(trimmedLine, record.name) {
			leadingWhitespace := split(line, record.name)[0]
			parts := split(trimmedLine, ":")
			if len(parts) >= 2 {
				lines[i] = tprintf(
					"%s%s:%s: %v",
					leadingWhitespace,
					parts[0],
					parts[1],
					newValue,
				)
				recordUpdated = true
				break
			}
		}

		if inTargetCluster && trimmedLine == "}," {
			break
		}
	}

	if !recordUpdated {
	    make_new_err(.CANNOT_UPDATE_RECORD, get_caller_location())
		return success
	}

	newContent := join(lines, "\n")
	writeSuccess := write_to_file(collectionPath, transmute([]byte)newContent, get_caller_location())
	if !writeSuccess {
        make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
	} else {
		success = true
	}

	return success
}

//deletes the passed in records value while retaining its name and data type
purge_record :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record)->bool{
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return success
    }


    collectionPath := concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)
	if !readSuccess {
	    make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return success
	}

	lines := split(string(data), "\n")
	defer delete(lines)

	newLines := make([dynamic]string)
	defer delete(newLines)

	inTargetCluster := false
	recordPurged := false

	for line in lines {
		trimmedLine := trim_space(line)

		if trimmedLine == "{" {
			inTargetCluster = false
		}

		if contains(trimmedLine, tprintf("cluster_name :identifier: %s", cluster.name)) {
			inTargetCluster = true
		}

		if inTargetCluster && contains(trimmedLine, tprintf("%s :", record.name)) {
			parts := split(trimmedLine, ":")
			if len(parts) >= 3 {
				// Keep the record name and type, but remove the value
				// Maintain the original indentation and spacing
				leadingWhitespace := split(line, record.name)[0]
				newLine := tprintf(
					"%s%s :%s:",
					leadingWhitespace,
					trim_space(parts[0]),
					trim_space(parts[1]),
				)
				append(&newLines, newLine)
				recordPurged = true
			} else {
				append(&newLines, line)
			}
		} else {
			append(&newLines, line)
		}

		if inTargetCluster && trimmedLine == "}," {
			inTargetCluster = false
		}
	}

	if !recordPurged {
	    make_new_err(.CANNOT_FIND_RECORD, get_caller_location())
		return success
	}

	newContent := join(newLines[:], "\n")
	writeSuccess := write_to_file(collectionPath, transmute([]byte)newContent, get_caller_location())
	if !writeSuccess{
        make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
        return success
	}else{
	    success = true
	}

	return success
}

//deletes a record from a cluster
erase_record :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> bool {
	using lib
	using fmt
	using strings

	success:= false

 collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return success
    }

	collectionPath := concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)
	if !readSuccess {
	    make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return success
	}

	lines := split(string(data), "\n")
	defer delete(lines)

	newLines := make([dynamic]string)
	defer delete(newLines)

	inTargetCluster := false
	recordFound := false
	isLastRecord := false
	recordCount := 0

	// First pass - count records in target cluster
	for line in lines {
		trimmedLine := trim_space(line)
		if contains(trimmedLine, tprintf("cluster_name :identifier: %s", cluster.name)) {
			inTargetCluster = true
			continue
		}
		if inTargetCluster {
			if trimmedLine == "}," {
				inTargetCluster = false
				continue
			}
			if len(trimmedLine) > 0 &&
			   !has_prefix(trimmedLine, "cluster_name") &&
			   !has_prefix(trimmedLine, "cluster_id") {
				recordCount += 1
			}
		}
	}

	// Second pass - rebuild content
	inTargetCluster = false
	for line in lines {
		trimmedLine := trim_space(line)

		if contains(trimmedLine, tprintf("cluster_name :identifier: %s", cluster.name)) {
			inTargetCluster = true
			append(&newLines, line)
			continue
		}

		if inTargetCluster {
			if has_prefix(trimmedLine, tprintf("%s :", record.name)) {
				recordFound = true
				if recordCount == 1 {
					isLastRecord = true
				}
				continue
			}

			if trimmedLine == "}," {
				if !isLastRecord {
					append(&newLines, line)
				} else {
					append(&newLines, "}")
				}
				inTargetCluster = false
				continue
			}
		}

		if !inTargetCluster || !has_prefix(trimmedLine, tprintf("%s :", record.name)) {
			append(&newLines, line)
		}
	}

	if !recordFound {
	    make_new_err(.CANNOT_FIND_RECORD, get_caller_location())
		return success
	}

	newContent := join(newLines[:], "\n")
	writeSuccess := write_to_file(collectionPath, transmute([]byte)newContent, get_caller_location())
	if !writeSuccess{
	    make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
		return success
	}else{
        success = true
	}

	return success
}

//Reads over the passed in collection and cluster looking for the passed in record,
//assigns the records name, type, and value to a new lib.Record and returns it
fetch_record :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> (lib.Record, bool){
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return Record{}, success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return Record{}, success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return Record{}, success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    data, readSuccess:= read_file(collectionPath, get_caller_location())
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return Record{}, success
    }
    defer delete(data)

    clusterBlocks:= split(string(data), "}")
    clusterContent, recordContent:string

    for c in clusterBlocks{
        if contains(c, tprintf("cluster_name :identifier: %s", cluster.name)){
            startIndex := index(c, "{")
			if startIndex != -1 {
				// Extract the content between braces
				clusterContent = c[startIndex + 1:]
				// Trim any leading or trailing whitespace
				clusterContent = trim_space(clusterContent)
				// return clone(clusterContent)
            }
        }
    }

   	for line in split_lines(clusterContent) {
		if contains(line, record.name) {
		    return parse_record(line), success
		}
	}


	return Record{}, success
}


//find and return the passed in records value as a string
//Remember to delete() the the return value from the calling procedure
get_record_value :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) ->(string, bool) {
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return "", success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return "", success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return "", success
    }

    collectionPath:= concat_standard_collection_name(cluster.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)
	if !readSuccess {
	    make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return "", success
	}

	lines := split(string(data), "\n")
	defer delete(lines)

	clusterStart := -1
	closingBrace := -1

	// Find the cluster and its closing brace
	for line, i in lines {
		if contains(line, cluster.name) {
			clusterStart = i
		}
		if clusterStart != -1 && contains(line, "}") {
			closingBrace = i
			break
		}
	}

	// If the cluster is not found or the structure is invalid, return an empty string
	if clusterStart == -1 || closingBrace == -1 {
        make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
        return "", success
	}

	type := tprintf(":%s:", record.type)
	for i in clusterStart ..= closingBrace {
		if contains(lines[i], record.name) {
			record := split(lines[i], type)
			if len(record) > 1 {
			    success = true
				return clone(trim_space(record[1])), success
			}
			make_new_err(.CANNOT_FIND_RECORD, get_caller_location())
			return "", success
		}
	}

	make_new_err(.CANNOT_READ_RECORD,get_caller_location())
	return "", success
}



//Used to ensure that the passed in records type is valid and if its shorthand assign the value as the longhand
//e.g if INT then assign INTEGER. Returns the type
//Remember to delete() the return value in the calling procedure
verify_record_data_type_is_valid :: proc(record: ^lib.Record) -> string {
    using lib
    using fmt
    using strings

	for type in RecordDataTypes {
		if record.type == type {
			#partial switch (record.type)
			{ 	//The first 8 cases handle if the type is shorthand
			case .STR:
				record.type = .STRING
				break
			case .INT:
				record.type = .INTEGER
				break
			case .FLT:
				record.type = .FLOAT
				break
			case .BOOL:
				record.type = .BOOLEAN
				break
			case .STR_ARRAY:
				record.type = .STRING_ARRAY
				break
			case .INT_ARRAY:
				record.type = .INTEGER_ARRAY
				break
			case .FLT_ARRAY:
				record.type = .FLOAT_ARRAY
				break
			case .BOOL_ARRAY:
				record.type = .BOOLEAN_ARRAY
				break
			case:
				//If not a valid shorhand just set the type to whatever it is so long as its valid in general
				record.type = type
				break
			}
		}
	}
	return clone(RecordDataTypesStrings[record.type])
}


//Returns the data type of the passed in record
get_record_type :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> ( string, bool) {
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return "", success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return "", success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return "", success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)

	if !readSuccess {
	    make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return "", success
	}

	clusters := split(string(data), "},")
	defer delete(clusters)

	for c in clusters {
		//check for cluster
		if contains(c, tprintf("cluster_name :identifier: %s", cluster.name)) {
			lines := split(c, "\n")
			for line in lines {
				line := trim_space(line)
				// Check if this line contains our record
				if has_prefix(line, tprintf("%s :", record.name)) {
					// Split the line into parts using ":"
					parts := split(line, ":")
					if len(parts) >= 2 {
					    success = true
						// Return the type of the record
						return clone(trim_space(parts[1])), success
					}
				}
			}
		}
	}

	return "", success
}



set_record_value ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> bool {
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return success
    }


   	recordType, getTypeSuccess := get_record_type(collection, cluster, record)

	intArrayValue:= make([dynamic]int, 0)
	defer delete(intArrayValue)

	fltArrayValue:= make([dynamic]f64, 0)
	defer delete(fltArrayValue)

	boolArrayValue:= make([dynamic]bool, 0)
	defer delete(boolArrayValue)

	charArrayValue:= make([dynamic]rune, 0)
	defer delete(charArrayValue)

	//Freeing memory for these at bottom of procedure
	stringArrayValue, timeArrayValue, dateTimeArrayValue, dateArrayValue, uuidArrayValue:[dynamic]string

	//Standard value allocation
	valueAny: any = 0
	ok: bool = false
	setValueOk := false
	switch (recordType) {
	case RecordDataTypesStrings[.INTEGER]:
		record.type = .INTEGER
		valueAny, ok = CONVERT_RECORD_TO_INT(rValue)
		setValueOk = ok
		break
	case RecordDataTypesStrings[.FLOAT]:
		record.type = .FLOAT
		valueAny, ok = CONVERT_RECORD_TO_FLOAT(rValue)
		setValueOk = ok
		break
	case RecordDataTypesStrings[.BOOLEAN]:
		record.type = .BOOLEAN
		valueAny, ok = CONVERT_RECORD_TO_BOOL(rValue)
		setValueOk = ok
		break
	case RecordDataTypesStrings[.STRING]:
		record.type = .STRING
		valueAny = append_qoutations(rValue)
		setValueOk = true
		break
	case RecordDataTypesStrings[.CHAR]:
		record.type = .CHAR
		if len(rValue) != 1 {
			setValueOk = false
		} else {
			valueAny = append_single_qoutations__string(rValue)
			setValueOk = true
		}
		break
	case RecordDataTypesStrings[.INTEGER_ARRAY]:
		record.type = .INTEGER_ARRAY
		verifiedValue := VERIFY_ARRAY_VALUES(RecordDataTypesStrings[.INTEGER_ARRAY], rValue)
		if !verifiedValue {
			return false
		}
		intArrayValue, ok := CONVERT_RECORD_TO_INT_ARRAY(rValue)
		valueAny = intArrayValue
		setValueOk = ok
		break
	case RecordDataTypesStrings[.FLOAT_ARRAY]:
		record.type = .FLOAT_ARRAY
		verifiedValue := VERIFY_ARRAY_VALUES(RecordDataTypesStrings[.FLOAT], rValue)
		if !verifiedValue {
			return false
		}
		fltArrayValue, ok := CONVERT_RECORD_TO_FLOAT_ARRAY(rValue)
		valueAny = fltArrayValue
		setValueOk = ok
		break
	case RecordDataTypesStrings[.BOOLEAN_ARRAY]:
		record.type = .BOOLEAN_ARRAY
		verifiedValue := VERIFY_ARRAY_VALUES(RecordDataTypesStrings[.BOOLEAN_ARRAY], rValue)
		if !verifiedValue {
			return false
		}
		boolArrayValue, ok := CONVERT_RECORD_TO_BOOL_ARRAY(rValue)
		valueAny = boolArrayValue
		setValueOk = ok
		break
	case RecordDataTypesStrings[.STRING_ARRAY]:
		record.type = .STRING_ARRAY
		stringArrayValue, ok := CONVERT_RECORD_TO_STRING_ARRAY(rValue)
		valueAny = stringArrayValue
		setValueOk = ok
		break
	case RecordDataTypesStrings[.CHAR_ARRAY]:
		record.type = .CHAR_ARRAY
		charArrayValue, ok := CONVERT_RECORD_TO_CHAR_ARRAY(rValue)
		valueAny = charArrayValue
		setValueOk = ok
		break
	case RecordDataTypesStrings[.DATE_ARRAY]:
		record.type = .DATA_ARRAY
		dateArrayValue, ok := CONVERT_RECORD_TO_DATE_ARRAY(rValue)
		valueAny = dateArrayValue
		setValueOk = ok
		break
	case RecordDataTypesStrings[.TIME_ARRAY]:
		record.type = .TIME_ARRAY
		timeArrayValue, ok := CONVERT_RECORD_TO_TIME_ARRAY(rValue)
		valueAny = timeArrayValue
		setValueOk = ok
		break
	case RecordDataTypesStrings[.DATETIME_ARRAY]:
		record.type = .DATETIME_ARRAY
		dateTimeArrayValue, ok := CONVERT_RECORD_TO_DATETIME_ARRAY(rValue)
		valueAny = dateTimeArrayValue
		setValueOk = ok
		break
	case RecordDataTypesStrings[.DATE]:
		record.type = .DATE
		date, ok := CONVERT_RECORD_TO_DATE(rValue)
		if ok {
			valueAny = date
			setValueOk = ok
		}
		break
	case RecordDataTypesStrings[.TIME]:
		record.type = .TIME
		time, ok := CONVERT_RECORD_TO_TIME(rValue)
		if ok {
			valueAny = time
			setValueOk = ok
		}
		break
	case RecordDataTypesStrings[.DATETIME]:
		record.type = .DATETIME
		dateTime, ok := CONVERT_RECORD_TO_DATETIME(rValue)
		if ok {
			valueAny = dateTime
			setValueOk = ok
		}
		break
	case RecordDataTypesStrings[.UUID]:
		record.type = .UUID
		uuid, ok := CONVERT_RECORD_TO_UUID(rValue)
		if ok {
			valueAny = uuid
			setValueOk = ok
		}
		break
	case RecordDataTypesStrings[.UUID_ARRAY]:
		record.type = .UUID_ARRAY
		uuidArrayValue, ok := CONVERT_RECORD_TO_UUID_ARRAY(rValue)
		valueAny = uuidArrayValue
		setValueOk = ok
		break
	case RecordDataTypesStrings[.NULL]:
		record.type = .NULL
		valueAny = .NULL
		setValueOk = true
		break
	}

	if setValueOk != true {
	errorLocation:= utils.get_caller_location()
		valueTypeError := utils.new_err(
			.INVALID_VALUE_FOR_EXPECTED_TYPE,
			utils.get_err_msg(.INVALID_VALUE_FOR_EXPECTED_TYPE),
			errorLocation
		)
		utils.throw_custom_err(
			valueTypeError,
			tprintf(
				"%sInvalid value given. Expected a value of type: %s%s",
				utils.BOLD_UNDERLINE,
				record.type,
				utils.RESET,
			),
		)
		utils.log_err(
			"User entered a value of a different type than what was expected.",
			#procedure,
		)

		return false
	}


	updateSuccess := update_record_value(collection, cluster, record, valueAny)
	if !updateSuccess{
	    return success
	}else{
        success = true
	}

	delete(intArrayValue)
	delete(fltArrayValue)
	delete(boolArrayValue)
	delete(stringArrayValue)
	delete(dateArrayValue)
	delete(timeArrayValue)
	delete(dateTimeArrayValue)
	delete(uuidArrayValue)

	return success
}


get_record_value_size :: proc(collection:^lib.Collection, cluster:^lib.Cluster, record: ^lib.Record) -> (int, bool) {
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return -1, success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return -2, success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return -3, success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return -4, success
    }

	clusterBlocks := split(string(data), "},")

	for c in clusterBlocks {
		if contains(c, tprintf("cluster_name :identifier: %s", cluster.name)) {
			lines := split(c, "\n")
			defer delete(lines)
			for line in lines {
				parts := split(line, ":")
				defer delete(parts)
				if has_prefix(line, tprintf("\t%s", record.name)) {
					//added the \t to the prefix because all records are indented in the plain text collection file - Marshall Burns Jan 2025
					parts := split(line, ":")
					if len(parts) == 3 {
						recordValue := trim_space(join(parts[2:], ":"))
						return len(recordValue), true
					}
				}
			}
		}
	}
	return 0, false
   }



//returns the number of records within the passed in cluster
get_record_count_within_cluster :: proc(collection:^lib.Collection, cluster:^lib.Cluster, record: ^lib.Record) -> (int, bool) {
    using lib
    using fmt
    using strings

    success:= false
    recordCount:= 0

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return -1, success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return -2, success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return -3, success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return -4, success
    }

	clusterBlocks := split(string(data), "},")
	defer delete(clusterBlocks)

	for c in clusterBlocks {
		if contains(c, tprintf("cluster_name :identifier: %s", cluster.name)) {
			lines := split(c, "\n")
			defer delete(lines)

			for line in lines {
				trimmedLine := trim_space(line)
				if len(trimmedLine) > 0 &&
				   !has_prefix(trimmedLine, "cluster_name") &&
				   !has_prefix(trimmedLine, "cluster_id") &&
				   !contains(trimmedLine, "#") &&
				   !contains(trimmedLine, METADATA_START) &&
				   !contains(trimmedLine, METADATA_END) &&
				   contains(trimmedLine, ":") {
					recordCount += 1
					success = true
				}
			}
		}
	}

	return recordCount, success
}

//reads over the passed in collection file and returns the number of records in that collection
//returns the number of record within an entire collection
get_record_count_within_collection :: proc(collection:^lib.Collection, cluster:^lib.Cluster, record: ^lib.Record) -> (int, bool) {
    using lib
    using fmt
    using strings

    success:= false
    recordCount:= 0

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return -1, success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return -2, success
    }

    recordExists:= check_if_record_exists_in_cluster(collection, cluster, record)
    if !recordExists{
        make_new_err(.RECORD_DOES_NOT_EXIST_IN_CLUSTER, get_caller_location())
        return -3, success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return -4, success
    }

	content := string(data)
	defer delete(content)

	// Skip metadata section
	if metadataEnd := index(content,METADATA_END);
	   metadataEnd >= 0 {
		content = content[metadataEnd + len(METADATA_END):]
	}

	clusterBlocks := split(content, "},")
	defer delete(clusterBlocks)


	for c in clusterBlocks {
		if !contains(c, "cluster_name :identifier:") {
			continue // Skip non-cluster content
		}
		lines := split(c, "\n")
		defer delete(lines)

		for line in lines {
			trimmedLine := trim_space(line)
			if len(trimmedLine) > 0 &&
			   !has_prefix(trimmedLine, "cluster_name") &&
			   !has_prefix(trimmedLine, "cluster_id") &&
			   contains(trimmedLine, ":") &&
			   !contains(trimmedLine, METADATA_START) &&
			   !contains(trimmedLine, METADATA_END) {
				recordCount += 1
				success = true
			}
		}
	}

	return recordCount,  success
}





//Reads over the passed in collection and a specific cluster for a record by name, returns true if found
check_if_record_exists_in_cluster :: proc(collection:^lib.Collection, cluster:^lib.Cluster, record: ^lib.Record) -> bool {
	using lib
	using fmt
	using strings

	success:= false

	collectionPath := concat_standard_collection_name(collection.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)

	if !readSuccess {
		make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return success
	}

	content := string(data)
	defer delete(content)

	clusterBlocks := split(content, "},")
	defer delete(clusterBlocks)

	for c in clusterBlocks {
		c := trim_space(c)
		if contains(c, tprintf("cluster_name :identifier: %s", cluster.name)) {
			// Found the correct cluster, now look for the record
			lines := split(c, "\n")
			for line in lines {
				line := trim_space(line)
				if has_prefix(line, tprintf("%s :", record.name)) {
				    success = true
					break
				}
			}
		}
	}

	//if the record wasn't found in the cluster the throw error
	if success == false {
		make_new_err(.CANNOT_FIND_RECORD, get_caller_location())
	}

	return success
}


// helper used to parse records into 3 parts, the name, type and value. Appends to a struct then returns
// //rememeber to delete the return values in the calling procedure
parse_record :: proc(recordAsString: string) -> lib.Record {
    using lib
    using strings
    using strings

    newRecordDataType: RecordDataTypes

	recordParts := split(recordAsString, ":")
	if len(recordParts) < 2 {
		return Record{}
	}

	recordName := trim_space(recordParts[0])
	recordType := trim_space(recordParts[1])
	recordValue := trim_space(recordParts[2])

	// Find the enum value by looking up the string in the RecordDataTypesStrings map
	for  dataTypeStringValue, dataTypeToken in RecordDataTypesStrings {
		if dataTypeStringValue == recordType {
			newRecordDataType= dataTypeToken
			break
		}
	}

	return Record { name = clone(recordName), type = newRecordDataType, value = clone(recordValue)}
}
