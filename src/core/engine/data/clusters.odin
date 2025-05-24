package  data

import lib "../../../library"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math/rand"
import "core:os"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file contains all the logic for interacting with
            clusters within the OstrichLite engine.
*********************************************************/

//Creates a new lib.Cluster, assigns its members with the passed i args
//Returns a pointer to the new lib.Cluster
@(require_results)
make_new_cluster :: proc(collection: ^lib.Collection, clusterName: string) -> ^lib.Cluster {
	using lib

    cluster := new(Cluster)
    cluster.parent = collection^
	cluster.name = clusterName //Todo: add a check for the length of and special chars in the name
	cluster.id = 0 //numbers will be auto-incremented per collections
	cluster.numberOfRecords = 0
	cluster.records= make([dynamic]Record, 0)
    // cluster.size = 0 //Might not use the size member during creation???
	return cluster
}

//writes the physical cluster block to the passed in collection
//Assigns the clusters name and id with the passed in cluster.name and cluster.id
@(require_results)
create_cluster_block_in_collection :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster) -> bool{
    using lib
    using strings

    success:=false
    buf:= new([32]byte)
    defer free(buf)

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  success
    }

    clusterAlreadyExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if clusterAlreadyExists{
        make_new_err(.CLUSTER_ALREADY_EXISTS_IN_COLLECTION, get_caller_location())
        return  success
    }
    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    clusterNameLine:[]string= {"{\n\tcluster_name :identifier: %n"}
    clusterIDLine:[]string= {"\n\tcluster_id :identifier: %i\n\t\n},\n"}

    defer delete(clusterNameLine)
    defer delete(clusterIDLine)

    file, openSuccess := os.open(collectionPath, os.O_APPEND | os.O_WRONLY, 0o666)
    if openSuccess != 0 {
        make_new_err(.CANNOT_OPEN_FILE, get_caller_location())
        return success
    }

    //Find the cluster name placeholder and write the new the clusterName in its place
    for i:= 0; i < len(clusterNameLine); i+= 1{
        if contains(clusterNameLine[i], "%n"){
            newClusterName, replaceSuccess := replace(clusterNameLine[i], "%n", cluster.name, -1)
            defer delete(newClusterName)

            if !replaceSuccess{
                make_new_err(.CANNOT_UPDATE_CLUSTER, get_caller_location())
                return success
            }

            _ , writeSuccess:= os.write(file, transmute([]u8)newClusterName)
            if writeSuccess != 0{
                make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
                return success
            }
        }
    }

    //Find the cluster ID placeholder and write the new the clusterID in its place
    for i:= 0; i < len(clusterIDLine); i += 1{
        if contains(clusterIDLine[i], "%i"){
            newClusterID, replaceSuccess:= replace(clusterIDLine[i], "%i", strconv.append_int(buf[:], cluster.id, 10), -1)
            defer delete(newClusterID)

            if !replaceSuccess{
                make_new_err(.CANNOT_UPDATE_CLUSTER, get_caller_location())
                return success
            }

            _ , writeSuccess:= os.write(file, transmute([]u8)newClusterID)
            if writeSuccess != 0{
                make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
                return success
            }else{
                success = true
            }
        }
    }

    os.close(file)
    return success
}

//Renames a cluster to the passed in newName arg. The old name is passed in via ^cluster.name
@(require_results)
rename_cluster :: proc(collection: ^lib.Collection,  cluster: ^lib.Cluster, newName: string) ->bool{
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  success
    }

    //Check that the name of the cluster that the user wants to rename DOES IN FACT exist
    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return  success
    }

    newCluster:= make_new_cluster(collection, newName)
    defer free(newCluster)

    //Now check if a cluster with the new name is already in use by a cluster in the passed in collection
    clusterExistsInCollection := check_if_cluster_exsists_in_collection(collection, newCluster)
    if clusterExistsInCollection {
        make_new_err(.CLUSTER_ALREADY_EXISTS, get_caller_location())
        return success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return success
    }

    clusterBlocks:= split(string(data), "},")
    defer delete(clusterBlocks)

    newConent := make([dynamic]u8)
    defer delete(newConent)

    clusterFound:= false

    for clusterBlock in clusterBlocks{
        clusterNameStartIndex := index(clusterBlock, "cluster_name :identifier:")
        //If "cluster_name :" is not found, skip this cluster
        if clusterNameStartIndex == - 1 do continue
        //Move the start index to after "cluster_name :"
        clusterNameStartIndex +=  len("cluster_name :identifier:")
        //Find the end of the cluster name
        clusterNameEndIndex:= index(clusterBlock[clusterNameStartIndex:], "\n")

        if clusterNameEndIndex != -1 {
            clusterName:= trim_space(clusterBlock[clusterNameStartIndex:][:clusterNameEndIndex])
            defer delete(clusterName)

            //A cluster with the the oldName has been found, so lets rename it
            if clusterName == cluster.name{
                clusterFound = true
                newClusterNameLine, replaceError:= replace(clusterBlock,
                    fmt.tprintf("cluster_name :identifier: %s", cluster.name),
                    fmt.tprintf("cluster_name :identifier: %s", newName),1
                )
                append(&newConent, ..transmute([]u8)newClusterNameLine)
                append(&newConent, "},")
            }else if len(trim_space(clusterBlock)) > 0 {
                append(&newConent, ..transmute([]u8)clusterBlock)
                append(&newConent, "},")
            }
        }
    }

    if !clusterFound{
        make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
        return clusterFound
    }

    writeSuccess:= write_to_file(collectionPath, newConent[:], get_caller_location())
    if !writeSuccess{
        make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
        return writeSuccess
    }else{
        success = true
    }

    return success
}

//Finds and deletes the cluster with the passed in cluster.name
@(require_results)
erase_cluster ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster)-> bool{
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return  success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return success
    }

    content:= string(data)
    defer delete(content)

    metadataHeaderEnd:= index(content, METADATA_END)
    metadataHeaderEnd += len(METADATA_END) + 1

    //split the collection(content) into 2 parts, the metadata header and the body
    metadataHeader := content[:metadataHeaderEnd]
    collectionBody:= content[metadataHeaderEnd:]

    clusterBlocks:= split(content, "},")
    defer delete(clusterBlocks)

    newConent := make([dynamic]u8)
    defer delete(newConent)

    append(&newConent, ..transmute([]u8)metadataHeader)

    clusterFound:= false

    for clusterBlock in clusterBlocks{
        clusterNameStartIndex := index(clusterBlock, "cluster_name :identifier:")
        //If "cluster_name :" is not found, skip this cluster
        if clusterNameStartIndex == - 1 {
            //Move the start index to after "cluster_name :"
            clusterNameStartIndex +=  len("cluster_name :identifier:")
            //Find the end of the cluster name
            clusterNameEndIndex:= index(clusterBlock[clusterNameStartIndex:], "\n")

            if clusterNameEndIndex != -1 {
                clusterName:= trim_space(clusterBlock[clusterNameStartIndex:][:clusterNameEndIndex])
                defer delete(clusterName)

                //A cluster with the the oldName has been found, so lets rename it
                if clusterName == cluster.name{
                    clusterFound = true
                    continue
                }
            }
        }

        if len(trim_space(clusterBlock)) > 0 {
            append(&newConent, ..transmute([]u8)clusterBlock)
            append(&newConent, "},")
        }
    }


    if !clusterFound{
        make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
        return success
    }

    writeSuccess:= write_to_file(collectionPath, newConent[:], get_caller_location())
    if !writeSuccess{
        make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
    }else{
        success =  true
    }

    return success
}

//Finds and returns the passed in cluster and all its data as a whole, excluding the identifier typed records
//Dont forget to delete the return value in the calling prcoedure
@(require_results)
fetch_cluster ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster)-> (string, bool){
    using lib
    using fmt
    using strings

    success:= false
    clusterAsString:=""

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  clusterAsString, success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return  clusterAsString, success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if!readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return "", success
    }


    clusterBlocks:= split(string(data), "},")
    defer delete(clusterBlocks)

    for clusterBlock in clusterBlocks{
       	if contains(clusterBlock, tprintf("cluster_name :identifier: %s", cluster.name)){
            clusterNameStartIndex := index(clusterBlock, "{")
            if clusterNameStartIndex != -1 {
               	clusterAsString = clusterBlock[clusterNameStartIndex + 1:]
                clusterAsString = trim_space(clusterAsString)
                success = true
            }
        }else{
            continue
        }
        make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
        break
    }

    return clone(clusterAsString), success
}

//Deletes all data within a cluster excluding the name, id all while retaining the clusters structure
@(require_results)
purge_cluster ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster) -> bool{
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return  success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if!readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return success
    }
    content:= string(data)
    defer delete(content)

    clusterBlocks := split(content, "},")
    defer delete(clusterBlocks)

    newContent := make([dynamic]u8)
    defer delete(newContent)

    metadataHeaderEnd := index(content, METADATA_END)
    metadataHeaderEnd += len(METADATA_END) + 1
    append(&newContent, ..transmute([]u8)content[:metadataHeaderEnd])

    clusterFound := false
    for clusterBlock in clusterBlocks {
        if contains(clusterBlock, fmt.tprintf("cluster_name :identifier: %s", cluster.name)) {
            clusterFound = true
            lines := split(clusterBlock, "\n")
            defer delete(lines)

            append(&newContent, '{')
            append(&newContent, '\n')

            for line in lines {
                trimmedLine := trim_space(line)
                defer delete(trimmedLine)

                if contains(trimmedLine, "cluster_name :identifier:") ||
                   contains(trimmedLine, "cluster_id :identifier:") {
                    // Preserve indentation
                    indent := index(line, trimmedLine)
                    if indent > 0 {
                        append(&newContent, ..transmute([]u8)repeat(" ", indent))
                    }
                    append(&newContent, ..transmute([]u8)trimmedLine)
                    append(&newContent, '\n')
                }
            }
            append(&newContent, ..transmute([]u8)tprintf("\t\n},"))
        } else if len(trim_space(clusterBlock)) > 0 {
            append(&newContent, ..transmute([]u8)clusterBlock)
            append(&newContent, "},")
        }
    }

    if !clusterFound {
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return success
    }

    writeSuccess := write_to_file(collectionPath, newContent[:], get_caller_location())
    if !writeSuccess {
        make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
        return success
    }

    success = true
    return success
}

//Read over the passed in collection and try to find the a cluster that matches the name of the passed in cluster arg
@(require_results)
check_if_cluster_exsists_in_collection ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster) ->bool{
    using lib
    using fmt
    using strings

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return  success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return success
    }

    clusterBlocks := split(string(data), "},")
    defer delete(clusterBlocks)

    for clusterBlock in clusterBlocks{
        clusterBlock:= trim_space(clusterBlock)
        defer delete(clusterBlock)

        if clusterBlock == "" do continue
        //Find the cluster name in the current cluste
        clusterNameStartIndex := index(clusterBlock, "cluster_name :identifier:")
        //If "cluster_name :" is not found, skip this cluster
        if clusterNameStartIndex == - 1 do continue
        //Move the start index to after "cluster_name :"
        clusterNameStartIndex +=  len("cluster_name :identifier:")
        //Find the end of the cluster name
        clusterNameEndIndex:= index(clusterBlock[clusterNameStartIndex:], "\n")
        //If newline is not found, skip this cluster
        if  clusterNameEndIndex == -1 do continue
        //Extract the cluster name and remove leading/trailing whitespace
        clusterName:= trim_space(clusterBlock[clusterNameStartIndex:][:clusterNameEndIndex])
        defer delete(clusterName)
        //Compare the extracted cluster name with the provided cluster name
        if compare(clusterName, cluster.name) == 0 {
            success = true
            break
        }
    }
    return success
}

//Returns 2 dynamic arrays:
//1. ALL cluster ids in a collectionas i64
//2. ALL cluster ids in a collection as strings
//remember to delete the returned values in the calling procedure
@(require_results)
get_all_cluster_ids_in_collection :: proc(collection: ^lib.Collection) -> ([dynamic]i64, [dynamic]string) {
    using lib
    using fmt
    using strings
    using strconv


	IDs := make([dynamic]i64)
	idsStringArray := make([dynamic]string)

	collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  IDs, idsStringArray
    }

	collectionPath := concat_standard_collection_name(collection.name)
	defer delete(collectionPath)

	data, readSuccess := os.read_entire_file(collectionPath)
	defer delete(data)
	if !readSuccess {
		make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return IDs, idsStringArray
	}

	lines := split(string(data), "\n")
	defer delete(lines)

	clusterIDLine := "cluster_id :identifier:"
	defer delete(clusterIDLine)
	for line in lines {
		if contains(line, clusterIDLine) {
			idStr := trim_space(split(line, ":")[2])
			defer delete(idStr)
			ID, ok := parse_i64(idStr)
			if ok {
				append(&IDs, ID)
				append(&idsStringArray, idStr)
			} else {
			    //Todo: handle error here???
			}
		}
	}
	return IDs, idsStringArray
}

//Returns a dynamic array of all cluster names within the passed in collection
//Remember to delete return value in calling procedure
@(require_results)
get_all_cluster_names_in_collection :: proc(collection: ^lib.Collection) -> ([dynamic]string) {
    using lib
    using fmt
    using strings

    clusterNames := make([dynamic]string)

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  clusterNames
    }

    collectionPath := concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    data, readSuccess := os.read_entire_file(collectionPath)
    defer delete(data)
    if!readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return clusterNames
    }

    lines := split(string(data), "\n")
    defer delete(lines)

    clusterNameLine := "cluster_name :identifier:"
    defer delete(clusterNameLine)
    for line in lines {
        if contains(line, clusterNameLine) {
            name := trim_space(split(line, ":")[2])
            append(&clusterNames, name)
            delete(name)
        }
    }
    return clusterNames
}


// Reads over the passed in collection for the passed in cluster, then returns the id of that cluster
@(require_results)
get_clusters_id_by_name :: proc(collection: ^lib.Collection, cluster:^lib.Cluster) -> (clusterID:i64,success:bool,){
    using lib
    using fmt
    using strings
    using strconv

    clusterID= 0
    success=false

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


   	if collection.name != "" {
		collectionPath := concat_standard_collection_name(collection.name)
		defer delete(collectionPath)

		data, readSuccess := read_file(collectionPath, get_caller_location())
		defer delete(data)
		if !readSuccess {
			make_new_err(.CANNOT_READ_FILE, get_caller_location())
			return  -3, success
		}

		lines:= split(string(data), "\n")
		defer delete(lines)

		clusterNameLine := tprintf("cluster_name :identifier: %s", cluster.name)
		defer delete(clusterNameLine)

		clusterIDLine := "cluster_id :identifier:"
		defer delete(clusterIDLine)

		for i := 0; i < len(lines); i += 1 {
			if contains(lines[i], clusterNameLine) {
				for j := i + 1; j < len(lines) && j < i + 5; j += 1 {
					if contains(lines[j], clusterIDLine) {
						idStr := trim_space(split(lines[j], ":")[2])
						defer delete(idStr)
						clusterID, ok := parse_i64(idStr)
						if ok {
							success = true
							break
						} else {
							make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
							return -4, success
						}
					}
				}
			}
		}
    }

	return clusterID, success
}

//Reads over the passed in collection for the passed in cluster ID. If found return the name of the cluster
@(require_results)
get_clusters_name_by_id ::proc(collection: ^lib.Collection, clusterID:i64) -> (clusterName:string,success: bool,){
    using lib
    using fmt
    using strings

    clusterName = ""
    success = false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  "", success,
    }

    if collection.name != "" {
        collectionPath := concat_standard_collection_name(collection.name)
        defer delete(collectionPath)

        data, readSuccess := read_file(collectionPath, get_caller_location())
        defer delete(data)

        if !readSuccess {
            make_new_err(.CANNOT_READ_FILE, get_caller_location())
            return "", success
        }

        clusterBlocks := split(string(data), "},")
        defer delete(clusterBlocks)

        for clusterBlock in clusterBlocks {
            if contains(clusterBlock, fmt.tprintf("cluster_id :identifier: %d", clusterID)) {
                lines := split(clusterBlock, "\n")
                defer delete(lines)

                for line in lines {
                    if contains(line, "cluster_name :identifier:") {
                        trimmedLine := trim_space(line)
                        defer delete(trimmedLine)
                        nameStartIndex := index(trimmedLine, "cluster_name :identifier:") + len("cluster_name :identifier:")
                        clusterName = trim_space(trimmedLine[nameStartIndex:])
                        success = true
                        break
                    }
                }
                break
            }
        }
    }

    return  clusterName, success
}

//Returns the size of the passed in cluster in bytes, this EXCLUDES the following:
//1. The opening curly brace
//2. The closing curly brace and it trailing comma
//3. The cluster name
//4. The cluster id
//5. Tab characters
//6. Newline characters
//7. Whitespace characters
@(cold, require_results)
get_cluster_size ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster) -> (int, bool){
    using lib
    using fmt
    using strings

    success := false
    size := 0

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  -1, success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return  -2, success
    }

    collectionPath := concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    data, readSuccess := read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return -3, success
    }


    clusterBlocks := split(string(data), "},")
    defer delete(clusterBlocks)

    for clusterBlock in clusterBlocks {
        if contains(clusterBlock, fmt.tprintf("cluster_name :identifier: %s", cluster.name)) {
            // Find the start of cluster content (after cluster name and id)
            lines := split(clusterBlock, "\n")
            defer delete(lines)

            contentStart := false
            for line in lines {
                trimmed := trim_space(line)
                defer delete(trimmed)
                // Skip cluster name and id lines
                if contains(trimmed, "cluster_name :identifier:") ||
                   contains(trimmed, "cluster_id :identifier:") {
                    continue
                }

                // Skip empty lines and braces
                if trimmed == "" || trimmed == "{" {
                    continue
                }

                // Count only the actual content, removing whitespace and special characters
                size += len(trim_space(line))
            }

            success = true
            break
        }
    }

    return  size, success
}


