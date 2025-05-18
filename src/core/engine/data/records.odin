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


create_record_within_cluster :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> bool{
    using lib

    success:= false

    collectionPath:= concat_standard_collection_name(collection.name)
    data, readSuccess:= read_file(collectionPath, get_caller_location())

    if !readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
    }



    return success
}

// Creates a new lib.cluster, assigns its members with the passed in args, returns pointer to new lib.Record
make_new_record :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster) -> ^lib.Record{
    using lib

    record:= new(Record)
    record.grandparent = collection^
    record.parent = cluster^
    record.id = 0
    record.name= ""
    record.type = ""
    record.value = ""

    return record
}


//Reads over the passed in collection and a specific cluster for a record by name, returns true if found
check_if_record_exists_in_cluster :: proc(collection:^lib.Collection, cluster:^lib.Cluster, record: ^lib.Record) -> bool {
	using lib

	//instead of passing 3 args I could just pass the ^lib.Collection arg and in the function itslef I could access its "grandchild" like this ---->  collection.clusters[0].records[0].name
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
