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
            collections within the OstrichLite engine.
*********************************************************/

// Creates a new lib.cluster, assigns its members with the passed in args, returns pointer to new lib.Record
make_new_record :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, recordName:string) -> ^lib.Record{
    using lib

    record:= new(Record)
    record.grandparent = collection^
    record.parent = cluster^
    record.id = 0
    record.name= recordName
    record.type = ""
    record.value = ""

    return record
}

//Appends the physcal recode line to the passed in cluster within the passed in collection
create_record_within_cluster :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> bool{
    using lib

    success:= false

    collectionPath:= concat_standard_collection_name(collection.name)
    data, readSuccess:= read_file(collectionPath, get_caller_location())

    if !readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
    }

    content := string(data)
    defer delete(content)

	lines := strings.split(content, "\n")
	defer delete(lines)

	clusterStart := -1
	closingBrace := -1

	// Find the cluster and its closing brace
	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], cluster.name) {
			clusterStart = i
		}
		if clusterStart != -1 && strings.contains(lines[i], "}") {
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
	newRecordLine := fmt.tprintf("\t%s :%s: %s", record.name, record.type, record.value)

	// Insert the new line and adjust the closing brace
	oldContent := make([dynamic]string, len(lines) + 1)
	copy(oldContent[:closingBrace], lines[:closingBrace])
	oldContent[closingBrace] = newRecordLine
	oldContent[closingBrace + 1] = "},"
	if closingBrace + 1 < len(lines) {
		copy(oldContent[closingBrace + 2:], lines[closingBrace + 1:])
	}
	newContent := strings.join(oldContent[:], "\n")

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

    success:= false
	collectionPath := concat_standard_collection_name(collection.name)

	if !check_if_cluster_exsists_in_collection(collection, cluster) {
        make_new_err(.RECORD_ALREADY_EXISTS_IN_CLUSTER, get_caller_location())
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

	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)

	if !readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
	    return success
	}

	content := string(data)
	defer delete(content)

	clusterBlocks := strings.split(content, "},")
	defer delete(clusterBlocks)

	newContent := make([dynamic]u8)
	defer delete(newContent)

	recordFound := false

		for c in clusterBlocks {
			c := strings.trim_space(c)
			if strings.contains(c, fmt.tprintf("cluster_name :identifier: %s", cluster.name)) {
				// Found the correct cluster, now look for the record to rename
				lines := strings.split(c, "\n")
				newCluster := make([dynamic]u8)
				defer delete(newCluster)

			for line in lines {
				trimmedLine := strings.trim_space(line)
				if strings.has_prefix(trimmedLine, fmt.tprintf("%s :", oldRecord.name)) {
					// Found the record to rename
					recordFound = true
					newLine, _:= strings.replace(trimmedLine,fmt.tprintf("%s :", oldRecord.name),fmt.tprintf("%s :", newRecord.name),1,)
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


//find and return the passed in records value as a string
//Remember to delete() the the return value from the calling procedure
get_record_value :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> string {
    using lib

    collectionPath:= concat_standard_collection_name(cluster.name)
	data, readSuccess := read_file(collectionPath, get_caller_location())
	defer delete(data)

	if !readSuccess {
	    make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return ""
	}

	content := string(data)
	defer delete(content)

	lines := strings.split(content, "\n")
	defer delete(lines)

	clusterStart := -1
	closingBrace := -1

	// Find the cluster and its closing brace
	for line, i in lines {
		if strings.contains(line, cluster.name) {
			clusterStart = i
		}
		if clusterStart != -1 && strings.contains(line, "}") {
			closingBrace = i
			break
		}
	}

	// If the cluster is not found or the structure is invalid, return an empty string
	if clusterStart == -1 || closingBrace == -1 {
        make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
        return ""
	}

	type := fmt.tprintf(":%s:", record.type)
	for i in clusterStart ..= closingBrace {
		if strings.contains(lines[i], record.name) {
			record := strings.split(lines[i], type)
			if len(record) > 1 {
				return strings.clone(strings.trim_space(record[1]))
			}
			make_new_err(.CANNOT_FIND_RECORD, get_caller_location())
			return ""
		}
	}

	make_new_err(.CANNOT_READ_RECORD,get_caller_location())
	return ""
}


//Reads over the passed in collection and a specific cluster for a record by name, returns true if found
check_if_record_exists_in_cluster :: proc(collection:^lib.Collection, cluster:^lib.Cluster, record: ^lib.Record) -> bool {
	using lib

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

	clusterBlocks := strings.split(content, "},")
	defer delete(clusterBlocks)

	for c in clusterBlocks {
		c := strings.trim_space(c)
		if strings.contains(c, fmt.tprintf("cluster_name :identifier: %s", cluster.name)) {
			// Found the correct cluster, now look for the record
			lines := strings.split(c, "\n")
			for line in lines {
				line := strings.trim_space(line)
				if strings.has_prefix(line, fmt.tprintf("%s :", record.name)) {
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
