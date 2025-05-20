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
create_cluster_block_in_collection :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster) -> bool{
    using lib

    success:=false
    buf:= new([32]byte)
    defer free(buf)

    collectionExists:= check_if_collection_exists(collection)
    if collectionExists{
        make_new_err(.COLLECTION_ALREADY_EXISTS, get_caller_location())
        return  success
    }

    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExists{
        make_new_err(.CLUSTER_DOES_NOT_EXIST_IN_COLLECTION, get_caller_location())
        return  success
    }

    clusterNameLine:[]string= {"{\n\tcluster_name :identifier: %n"}
    clusterIDLine:[]string= {"\n\tcluster_id :identifier: %i\n\t\n},\n"}

    defer delete(clusterNameLine)
    defer delete(clusterIDLine)

    collectionPath, openSuccess := os.open(collection.name, os.O_APPEND | os.O_WRONLY, 0o666)
    if openSuccess != 0 {
        make_new_err(.CANNOT_OPEN_FILE, get_caller_location())
        return success
    }

    //Find the cluster name placeholder and write the new the clusterName in its place
    for i:= 0; i < len(clusterNameLine); i+= 1{
        if strings.contains(clusterNameLine[i], "%n"){
            newClusterName, replaceSuccess := strings.replace(clusterNameLine[i], "%n", cluster.name, -1)
            if !replaceSuccess{
                make_new_err(.CANNOT_UPDATE_CLUSTER, get_caller_location())
                return success
            }

            writeClusterName, writeSuccess:= os.write(collectionPath, transmute([]u8)newClusterName)
            if writeSuccess != 0{
                make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
                return success
            }
        }
    }

    //Find the cluster ID placeholder and write the new the clusterID in its place
    for i:= 0; i < len(clusterIDLine); i += 1{
        if strings.contains(clusterIDLine[i], "%i"){
            newClusterID, replaceSuccess:= strings.replace(clusterIDLine[i], "%i", strconv.append_int(buf[:], cluster.id, 10), -1)
            if !replaceSuccess{
                make_new_err(.CANNOT_UPDATE_CLUSTER, get_caller_location())
                return success
            }

            writeClusterID, writeSuccess:= os.write(collectionPath, transmute([]u8)newClusterID)
            if writeSuccess != 0{
                make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
                return success
            }
        }
    }

    success = true
    os.close(collectionPath)
    return success
}

//Renames a cluster to the passed in newName arg. The old name is passed in via ^cluster.name
rename_cluster :: proc(collection: ^lib.Collection,  cluster: ^lib.Cluster, newName: string) ->bool{
    using lib

    success:= false

    collectionExists:= check_if_collection_exists(collection)
    if !collectionExists{
        make_new_err(.COLLECTION_DOES_NOT_EXIST, get_caller_location())
        return  success
    }

    //Check if the new name is already in use by a cluster in the passed in collection
    clusterExistsInCollection := check_if_cluster_exsists_in_collection(collection, cluster)
    if clusterExistsInCollection {
        make_new_err(.CLUSTER_ALREADY_EXISTS, get_caller_location())
        return success
    }

    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    newCluster:= make_new_cluster(collection, newName )
    defer free(newCluster)

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return success
    }

    clusterBlocks:= strings.split(string(data), "},")
    defer delete(clusterBlocks)

    newConent := make([dynamic]u8)
    defer delete(newConent)

    clusterFound:= false

    for clusterBlock in clusterBlocks{
        clusterNameStartIndex := strings.index(clusterBlock, "cluster_name :identifier:")
        //If "cluster_name :" is not found, skip this cluster
        if clusterNameStartIndex == - 1 do continue
        //Move the start index to after "cluster_name :"
        clusterNameStartIndex +=  len("cluster_name :identifier:")
        //Find the end of the cluster name
        clusterNameEndIndex:= strings.index(clusterBlock[clusterNameStartIndex:], "\n")

        if clusterNameEndIndex != -1 {
            clusterName:= strings.trim_space(clusterBlock[clusterNameStartIndex:][:clusterNameEndIndex])

            //A cluster with the the oldName has been found, so lets rename it
            if clusterName == cluster.name{
                clusterFound = true
                newClusterNameLine, replaceError:= strings.replace(clusterBlock,
                    fmt.tprintf("cluster_name :identifier: %s", cluster.name),
                    fmt.tprintf("cluster_name :identifier: %s", newName),1
                )
                append(&newConent, ..transmute([]u8)newClusterNameLine)
                append(&newConent, "},")
            }else if len(strings.trim_space(clusterBlock)) > 0 {
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
erase_cluster ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster)-> bool{
    using lib

    succces:= false
    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    clusterExistsInCollection := check_if_cluster_exsists_in_collection(collection, cluster)
    if !clusterExistsInCollection{
        make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
        return succces
    }

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return succces
    }

    content:= string(data)
    defer delete(content)

    metadataHeaderEnd:= strings.index(content, METADATA_END)
    metadataHeaderEnd += len(METADATA_END) + 1

    //split the collection(content) into 2 parts, the metadata header and the body
    metadataHeader := content[:metadataHeaderEnd]
    collectionBody:= content[metadataHeaderEnd:]

    clusterBlocks:= strings.split(content, "},")
    defer delete(clusterBlocks)

    newConent := make([dynamic]u8)
    defer delete(newConent)

    append(&newConent, ..transmute([]u8)metadataHeader)

    clusterFound:= false

    for clusterBlock in clusterBlocks{
        clusterNameStartIndex := strings.index(clusterBlock, "cluster_name :identifier:")
        //If "cluster_name :" is not found, skip this cluster
        if clusterNameStartIndex == - 1 {
            //Move the start index to after "cluster_name :"
            clusterNameStartIndex +=  len("cluster_name :identifier:")
            //Find the end of the cluster name
            clusterNameEndIndex:= strings.index(clusterBlock[clusterNameStartIndex:], "\n")

            if clusterNameEndIndex != -1 {
                clusterName:= strings.trim_space(clusterBlock[clusterNameStartIndex:][:clusterNameEndIndex])

                //A cluster with the the oldName has been found, so lets rename it
                if clusterName == cluster.name{
                    clusterFound = true
                    continue
                }
            }
        }

        if len(strings.trim_space(clusterBlock)) > 0 {
            append(&newConent, ..transmute([]u8)clusterBlock)
            append(&newConent, "},")
        }
    }


    if !clusterFound{
        make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
        return succces
    }

    writeSuccess:= write_to_file(collectionPath, newConent[:], get_caller_location())
    if !writeSuccess{
        make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
    }else{
        succces =  true
    }

    return succces
}

//Finds and returns the passed in cluster and all its data as a whole, excluding the identifier typed records
fetch_cluster ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster)-> (string, bool){
 using lib

 success:= false
 clusterAsString:string = ---

 collectionPath:= concat_standard_collection_name(collection.name)
 defer delete(collectionPath)

 clusterExistsInCollection := check_if_cluster_exsists_in_collection(collection, cluster)
 if!clusterExistsInCollection{
    make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
    return "", success
 }

 data, readSuccess:= read_file(collectionPath, get_caller_location())
 defer delete(data)
 if!readSuccess{
    make_new_err(.CANNOT_READ_FILE, get_caller_location())
    return "", success
 }


 clusterBlocks:= strings.split(string(data), "},")
 defer delete(clusterBlocks)

 for clusterBlock in clusterBlocks{
 	if strings.contains(clusterBlock, fmt.tprintf("cluster_name :identifier: %s", cluster.name)){
        clusterNameStartIndex := strings.index(clusterBlock, "{")
        if clusterNameStartIndex != -1 {
        	clusterAsString = clusterBlock[clusterNameStartIndex + 1:]
            clusterAsString = strings.trim_space(clusterAsString)
            success = true
        }
    }else{
        continue
    }
    make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
    break
 }

 return  strings.clone(clusterAsString), success
}

//Deletes all data within a cluster excluding the name, id all while retaining the clusters structure
purge_cluster ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster) -> bool{
    using lib
    success:= false

    collectionPath:= concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    clusterExistsInCollection := check_if_cluster_exsists_in_collection(collection, cluster)
    if!clusterExistsInCollection{
        make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
        return success
    }

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    defer delete(data)
    if!readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return success
    }
    content:= string(data)
    defer delete(content)

    clusterBlocks := strings.split(content, "},")
    defer delete(clusterBlocks)

    newContent := make([dynamic]u8)
    defer delete(newContent)

    metadataHeaderEnd := strings.index(content, METADATA_END)
    metadataHeaderEnd += len(METADATA_END) + 1
    append(&newContent, ..transmute([]u8)content[:metadataHeaderEnd])

    clusterFound := false
    for clusterBlock in clusterBlocks {
        if strings.contains(clusterBlock, fmt.tprintf("cluster_name :identifier: %s", cluster.name)) {
            clusterFound = true
            lines := strings.split(clusterBlock, "\n")
            defer delete(lines)

            append(&newContent, '{')
            append(&newContent, '\n')

            for line in lines {
                trimmedLine := strings.trim_space(line)
                if strings.contains(trimmedLine, "cluster_name :identifier:") ||
                   strings.contains(trimmedLine, "cluster_id :identifier:") {
                    // Preserve indentation
                    indent := strings.index(line, trimmedLine)
                    if indent > 0 {
                        append(&newContent, ..transmute([]u8)strings.repeat(" ", indent))
                    }
                    append(&newContent, ..transmute([]u8)trimmedLine)
                    append(&newContent, '\n')
                }
            }
            append(&newContent, ..transmute([]u8)fmt.tprintf("\t\n},"))
        } else if len(strings.trim_space(clusterBlock)) > 0 {
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
check_if_cluster_exsists_in_collection ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster) ->bool{
    using lib

    success:= false

    data, readSuccess:= read_file(collection.name, get_caller_location())
    defer delete(data)
    if !readSuccess{
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return success
    }


    clusterBlocks := strings.split(string(data), "},")
    defer delete(clusterBlocks)

    for clusterBlock in clusterBlocks{
        clusterBlock:= strings.trim_space(clusterBlock)
        if clusterBlock == "" do continue
        //Find the cluster name in the current cluste
        clusterNameStartIndex := strings.index(clusterBlock, "cluster_name :identifier:")
        //If "cluster_name :" is not found, skip this cluster
        if clusterNameStartIndex == - 1 do continue
        //Move the start index to after "cluster_name :"
        clusterNameStartIndex +=  len("cluster_name :identifier:")
        //Find the end of the cluster name
        clusterNameEndIndex:= strings.index(clusterBlock[clusterNameStartIndex:], "\n")
        //If newline is not found, skip this cluster
        if  clusterNameEndIndex == -1 do continue
        //Extract the cluster name and remove leading/trailing whitespace
        clusterName:= strings.trim_space(clusterBlock[clusterNameStartIndex:][:clusterNameEndIndex])
        //Compare the extracted cluster name with the provided cluster name
        if strings.compare(clusterName, cluster.name) == 0 {
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
get_all_cluster_ids_in_collection :: proc(collection: ^lib.Collection) -> ([dynamic]i64, [dynamic]string) {
	using lib

	//the following dynamic arrays DO NOT get deleted at the end of the procedure. They are deleted in the calling procedure
	IDs := make([dynamic]i64)
	idsStringArray := make([dynamic]string)

	fullPath := concat_standard_collection_name(collection.name)
	defer delete(fullPath)

	data, readSuccess := os.read_entire_file(fullPath)
	if !readSuccess {
		make_new_err(.CANNOT_READ_FILE, get_caller_location())
		return IDs, idsStringArray
	}

	lines := strings.split(string(data), "\n")
	defer delete(lines)

	clusterIDLine := "cluster_id :identifier:"
	for line in lines {
		if strings.contains(line, clusterIDLine) {
			idStr := strings.trim_space(strings.split(line, ":")[2])
			ID, ok := strconv.parse_i64(idStr)
			if ok {
				append(&IDs, ID)
				append(&idsStringArray, idStr)
			} else {
			    errorLocation:= get_caller_location()
				log_err(fmt.tprintf("Error parsing cluster ID: %s", idStr), errorLocation)
			}
		}
	}
	return IDs, idsStringArray
}

//Returns a dynamic array of all cluster names within the passed in collection
//Remember to delete return value in calling procedure
get_all_cluster_names_in_collection :: proc(collection: ^lib.Collection) -> ([dynamic]string) {
	using lib

    clusterNames := make([dynamic]string)

    fullPath := concat_standard_collection_name(collection.name)
    defer delete(fullPath)

    data, readSuccess := os.read_entire_file(fullPath)
    defer delete(data)
    if!readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return clusterNames
    }

    lines := strings.split(string(data), "\n")
    defer delete(lines)

    clusterNameLine := "cluster_name :identifier:"
    for line in lines {
        if strings.contains(line, clusterNameLine) {
            name := strings.trim_space(strings.split(line, ":")[2])
            append(&clusterNames, name)
        }
    }
    return clusterNames
}


// Reads over the passed in collection for the passed in cluster, then returns the id of that cluster
get_clusters_id_by_name :: proc(collection: ^lib.Collection, cluster:^lib.Cluster) -> (success:bool,clusterID:i64){
    using lib

    clusterID = -1
    success=false

   	if collection.name != "" {
		collectionPath := concat_standard_collection_name(collection.name)
		defer delete(collectionPath)

		data, readSuccess := os.read_entire_file(collectionPath)
		defer delete(data)

		if !readSuccess {
			make_new_err(.CANNOT_READ_FILE, get_caller_location())
			return success, clusterID
		}

		lines:= strings.split(string(data), "\n")
		defer delete(lines)

		clusterNameLine := fmt.tprintf("cluster_name :identifier: %s", cluster.name)
		clusterIDLine := "cluster_id :identifier:"

		for i := 0; i < len(lines); i += 1 {
			if strings.contains(lines[i], clusterNameLine) {
				for j := i + 1; j < len(lines) && j < i + 5; j += 1 {
					if strings.contains(lines[j], clusterIDLine) {
						idStr := strings.trim_space(strings.split(lines[j], ":")[2])
						clusterID, ok := strconv.parse_i64(idStr)
						if ok {
							success = true
							break
						} else {
							make_new_err(.CANNOT_FIND_CLUSTER, get_caller_location())
							break
						}
					}
				}
			}
		}
    }

	return success, clusterID
}

//Reads over the passed in collection for the passed in cluster ID. If found return the name of the cluster
get_clusters_name_by_id ::proc(collection: ^lib.Collection, clusterID:i64) -> (success: bool, clusterName:string){
    using lib
    clusterName = ""
    success = false

    if collection.name != "" {
        collectionPath := concat_standard_collection_name(collection.name)
        defer delete(collectionPath)

        data, readSuccess := read_file(collectionPath, get_caller_location())
        defer delete(data)

        if !readSuccess {
            make_new_err(.CANNOT_READ_FILE, get_caller_location())
            return success, clusterName
        }

        clusterBlocks := strings.split(string(data), "},")
        defer delete(clusterBlocks)

        for clusterBlock in clusterBlocks {
            if strings.contains(clusterBlock, fmt.tprintf("cluster_id :identifier: %d", clusterID)) {
                lines := strings.split(clusterBlock, "\n")
                defer delete(lines)

                for line in lines {
                    if strings.contains(line, "cluster_name :identifier:") {
                        trimmedLine := strings.trim_space(line)
                        nameStartIndex := strings.index(trimmedLine, "cluster_name :identifier:") + len("cluster_name :identifier:")
                        clusterName = strings.trim_space(trimmedLine[nameStartIndex:])
                        success = true
                        break
                    }
                }
                break
            }
        }
    }

    return success, clusterName
}

//Returns the size of the passed in cluster in bytes, this EXCLUDES the following:
//1. The opening curly brace
//2. The closing curly brace and it trailing comma
//3. The cluster name
//4. The cluster id
//5. Tab characters
//6. Newline characters
//7. Whitespace characters
get_cluster_size ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster) -> (bool, int){
    using lib

    success := false
    size := 0

    collectionPath := concat_standard_collection_name(collection.name)
    defer delete(collectionPath)

    data, readSuccess := read_file(collectionPath, get_caller_location())
    defer delete(data)
    if !readSuccess {
        make_new_err(.CANNOT_READ_FILE, get_caller_location())
        return success, size
    }


    clusterBlocks := strings.split(string(data), "},")
    defer delete(clusterBlocks)

    for clusterBlock in clusterBlocks {
        if strings.contains(clusterBlock, fmt.tprintf("cluster_name :identifier: %s", cluster.name)) {
            // Find the start of cluster content (after cluster name and id)
            lines := strings.split(clusterBlock, "\n")
            defer delete(lines)

            contentStart := false
            for line in lines {
                trimmed := strings.trim_space(line)
                // Skip cluster name and id lines
                if strings.contains(trimmed, "cluster_name :identifier:") ||
                   strings.contains(trimmed, "cluster_id :identifier:") {
                    continue
                }

                // Skip empty lines and braces
                if trimmed == "" || trimmed == "{" {
                    continue
                }

                // Count only the actual content, removing whitespace and special characters
                size += len(strings.trim_space(line))
            }

            success = true
            break
        }
    }

    return success, size
}


