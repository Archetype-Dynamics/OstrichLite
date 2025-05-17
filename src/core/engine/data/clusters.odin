package  data

import lib "../../../library"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math/rand"
import "core:os"


//Returns 2 dynamic arrays:
//1. ALL cluster ids in a collectionas i64
//2. ALL cluster ids in a collection as strings
get_all_cluster_ids_in_collection :: proc(collectionName: string) -> ([dynamic]i64, [dynamic]string) {
	using lib

	//the following dynamic arrays DO NOT get deleted at the end of the procedure. They are deleted in the calling procedure
	IDs := make([dynamic]i64)
	idsStringArray := make([dynamic]string)

	fullPath := concat_standard_collection_name(collectionName)
	defer delete(fullPath)

	data, readSuccess := os.read_entire_file(fullPath)
	if !readSuccess {
	errorLocation := get_caller_location()
		error := new_err(
			.CANNOT_READ_FILE,
			ErrorMessage[.CANNOT_READ_FILE],
			errorLocation
		)
		throw_err(error)
		log_err("Error reading collection file", errorLocation)
		return IDs, idsStringArray
	}

	content := string(data)
	lines := strings.split(content, "\n")
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

// Reads over the passed in collection for the passed in cluster, then returns the id of that cluster
get_cluster_id_by_name ::proc(collectionName, clusterName:string) -> (clusterID:i64){
    using lib
    clusterID = 0
    ok: bool = ---

   	if collectionName != "" {
		collectionPath := concat_standard_collection_name(collectionName)
		defer delete(collectionPath)

		data, readSuccess := os.read_entire_file(collectionPath)
		defer delete(data)

		if !readSuccess {
		errorLocation:= get_caller_location()
			readError := new_err(
				.CANNOT_READ_FILE,
				ErrorMessage[.CANNOT_READ_FILE],
				errorLocation
			)
			throw_err(readError)
			log_err("Error reading collection file", errorLocation)
			return clusterID
		}

		content:= string(data)
		lines:= strings.split(content, "\n")
		defer delete(lines)

		clusterNameLine := fmt.tprintf("cluster_name :identifier: %s", clusterName)
		clusterIDLine := "cluster_id :identifier:"

		for i := 0; i < len(lines); i += 1 {
			if strings.contains(lines[i], clusterNameLine) {
				for j := i + 1; j < len(lines) && j < i + 5; j += 1 {
					if strings.contains(lines[j], clusterIDLine) {
						idStr := strings.trim_space(strings.split(lines[j], ":")[2])
						clusterID, ok = strconv.parse_i64(idStr)
						if ok {
							break
						} else {
						    errorLocation:= get_caller_location()
						    error:= new_err(.CANNOT_FIND_CLUSTER,ErrorMessage[.CANNOT_FIND_CLUSTER],errorLocation)
						    fmt.println("ERROR: Error parsing cluster ID")
							log_err("Error parsing cluster ID", errorLocation)
							break
						}
					}
				}
			}
		}
    }

	return clusterID
}




create_cluster_block ::proc(collectionName: string, cluster: ^lib.Cluster) -> bool{
    using lib

    success:=false
    buf:= new([32]byte)
    defer free(buf)

    clusterExistsInCollection := check_if_cluster_exsists_in_collection(collectionName, cluster^)
    if clusterExistsInCollection {
        errorLocation:= get_caller_location()
        error:= new_err(.CLUSTER_ALREADY_EXISTS, ErrorMessage[.CLUSTER_ALREADY_EXISTS], errorLocation)
        throw_err(error)
        log_err("Error: Cluster Already Exists within collection cannot create", errorLocation)
        fmt.printfln("ERROR: Cluster %s already exists in collection %s", collectionName, cluster.name)
        return success
    }

    clusterNameLine:[]string= {"{\n\tcluster_name :identifier: %n"}
    clusterIDLine:[]string= {"\n\tcluster_id :identifier: %i\n\t\n},\n"}

    collectionPath, openSuccess := os.open(collectionName, os.O_APPEND | os.O_WRONLY, 0o666)
    if openSuccess != 0 {
        errorLocation:= get_caller_location()
        error := new_err(
            .CANNOT_OPEN_FILE,
            ErrorMessage[.CANNOT_OPEN_FILE],
            errorLocation
        )
        throw_err(error)
        log_err("Error opening collection file", errorLocation)
        return success
    }
    //Find the cluster name placeholder and write the new the clusterName in its place
    for i:= 0; i < len(clusterNameLine); i+= 1{
        if strings.contains(clusterNameLine[i], "%n"){
            newClusterName, replaceSuccess := strings.replace(clusterNameLine[i], "%n", cluster.name, -1)
            if !replaceSuccess{
                errorLocation:= get_caller_location()
                error:= new_err(.CANNOT_UPDATE_CLUSTER, ErrorMessage[.CANNOT_UPDATE_CLUSTER], errorLocation)
                throw_err(error)
                log_err("Error updating cluster name value", errorLocation)
            }

            writeClusterName, writeSuccess:= os.write(collectionPath, transmute([]u8)newClusterName)
            if writeSuccess != 0{
                errorLocation:= get_caller_location()
                error:= new_err(.CANNOT_WRITE_TO_FILE, ErrorMessage[.CANNOT_WRITE_TO_FILE], errorLocation)
                throw_err(error)
                log_err("Error placing cluster name into cluster block", errorLocation)
                return success
            }
        }
    }

    //Find the cluster ID placeholder and write the new the clusterID in its place
    for i:= 0; i < len(clusterIDLine); i += 1{
        if strings.contains(clusterIDLine[i], "%i"){
            newClusterID, replaceSuccess:= strings.replace(clusterIDLine[i], "%i", strconv.append_int(buf[:], cluster.id, 10), -1)
            if !replaceSuccess{
                errorLocation:= get_caller_location()
                error:= new_err(.CANNOT_UPDATE_CLUSTER, ErrorMessage[.CANNOT_UPDATE_CLUSTER], errorLocation)
                throw_err(error)
                log_err("Error updating cluster name value", errorLocation)
                return success
            }

            writeClusterID, writeSuccess:= os.write(collectionPath, transmute([]u8)newClusterID)
            if writeSuccess != 0{
                errorLocation := get_caller_location()
                error:= new_err(.CANNOT_WRITE_TO_FILE, ErrorMessage[.CANNOT_WRITE_TO_FILE], errorLocation)
                throw_err(error)
                log_err("Error writing cluster id into cluster block", errorLocation)
                return success
            }
        }
    }

    success = true
    os.close(collectionPath)
    return success
}

//Renames a cluster to the passed in newName arg. The old name is passed in via ^cluster.name
rename_cluster :: proc(collectionName, newName: string, cluster: ^lib.Cluster)->bool{
    using lib

    success:= false
    collectionPath:= concat_standard_collection_name(collectionName)
    defer delete(collectionPath)

    //Create a temp new cluster to assign the name value
    newCluster:= new(Cluster)
    newCluster.name = newName
    defer free(newCluster)


    //Check if the new name is already in use by a cluster in the passed in collection
    clusterExistsInCollection := check_if_cluster_exsists_in_collection(collectionName, newCluster^)
    if clusterExistsInCollection {
        errorLocation:= get_caller_location()
        error:= new_err(.CLUSTER_ALREADY_EXISTS, ErrorMessage[.CLUSTER_ALREADY_EXISTS], errorLocation)
        throw_err(error)
        log_err("Error: Cluster Already Exists within collection cannot create", errorLocation)
        fmt.printfln("ERROR: Cluster %s already exists in collection %s", collectionName, cluster.name)
        return success
    }

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    if !readSuccess{
        errorLocation:= get_caller_location()
        error:= new_err(.CANNOT_READ_FILE, ErrorMessage[.CANNOT_READ_FILE], errorLocation)
        throw_err(error)
        log_err("Error: Could not read file", errorLocation)
        return success
    }

    defer delete(data)
    content:= string(data)

    clusterBlocks:= strings.split(content, "},")
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
        errorLocation:= get_caller_location()
        error:= new_err(.CANNOT_FIND_CLUSTER, ErrorMessage[.CANNOT_FIND_CLUSTER], errorLocation)
        throw_err(error)
        log_err("Error finding cluster in collection", errorLocation)
        return clusterFound
    }

    writeSuccess:= write_to_file(collectionPath, newConent[:], get_caller_location())
    if !writeSuccess{
        errorLocation:= get_caller_location()
        error:= new_err(.CANNOT_WRITE_TO_FILE, ErrorMessage[.CANNOT_WRITE_TO_FILE], errorLocation)
        throw_err(error)
        log_err("Error writing cluster to collection", errorLocation)
        return writeSuccess
    }else{
        success = true
    }


    return success
}


//Finds and deletes the cluster with the passed in cluster.name
erase_cluster ::proc(collectionName:string, cluster: ^lib.Cluster)-> bool{
    using lib

    succces:= false
    collectionPath:= concat_standard_collection_name(collectionName)
    defer delete(collectionPath)

    data, readSuccess:= read_file(collectionPath, get_caller_location())
    if !readSuccess{
        errorLocation:= get_caller_location()
        error:= new_err(.CANNOT_READ_FILE, ErrorMessage[.CANNOT_READ_FILE], errorLocation)
        throw_err(error)
        log_err("Error: Could not read file", errorLocation)
        return succces
    }

    defer delete(data)
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
    append(&newConent, ..transmute([]u8)metadataHeader)
    defer delete(newConent)

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
        errorLocation:= get_caller_location()
        error:= new_err(.CANNOT_FIND_CLUSTER, ErrorMessage[.CANNOT_FIND_CLUSTER], errorLocation)
        throw_err(error)
        log_err("Error: Could not find cluster within collection", errorLocation)
        return succces
    }

    writeSuccess:= write_to_file(collectionPath, newConent[:], get_caller_location())
    if !writeSuccess{
        errorLocation:= get_caller_location()
        error:= new_err(.CANNOT_WRITE_TO_FILE, ErrorMessage[.CANNOT_WRITE_TO_FILE],errorLocation)
        throw_err(error)
        log_err("Error: Could not write cluster to collection", errorLocation)
    }else{
        succces =  true
    }

    return succces
}


//Read over the passed in collection and try to find the a cluster that matches the name of the passed in cluster arg
check_if_cluster_exsists_in_collection ::proc(collectionName:string, cluster: lib.Cluster) ->bool{
    using lib

    //Note sure if I need to handle an error here
    //because this is a a helper that is called in
    //other procs that already have error handling
    data, readSuccess:= read_file(collectionName, get_caller_location())
    defer delete(data)

    content:= string(data)
    defer delete(content)

    clusterBlocks := strings.split(content, "},")
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
            return true
        }
    }
    return false
}