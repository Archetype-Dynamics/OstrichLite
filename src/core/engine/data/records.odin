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
get_record_value :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) ->(string, bool) {
    using lib

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
        return "", success
	}

	type := fmt.tprintf(":%s:", record.type)
	for i in clusterStart ..= closingBrace {
		if strings.contains(lines[i], record.name) {
			record := strings.split(lines[i], type)
			if len(record) > 1 {
			    success = true
				return strings.clone(strings.trim_space(record[1])), success
			}
			make_new_err(.CANNOT_FIND_RECORD, get_caller_location())
			return "", success
		}
	}

	make_new_err(.CANNOT_READ_RECORD,get_caller_location())
	return "", success
}


//finds a the passed in record, and physically updates its data type. keeps its value which will eventually need to be changed
update_records_data_type :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record, newType: string) -> bool {
    using lib

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

	content := string(data)
	defer delete(content)

	lines := strings.split(content, "\n")
	defer delete(lines)

	newLines := make([dynamic]string)
	defer delete(newLines)

	inTargetCluster := false
	recordUpdated := false

	// Find the cluster and update the record
	for line in lines {
		trimmedLine := strings.trim_space(line)

		if trimmedLine == "{" {
			inTargetCluster = false
		}

		if strings.contains(trimmedLine, fmt.tprintf("cluster_name :identifier: %s", cluster.name)) {
			inTargetCluster = true
		}

		if inTargetCluster && strings.contains(trimmedLine, fmt.tprintf("%s :", record.name)) {
			// Keep the original indentation
			leadingWhitespace := strings.split(line, record.name)[0]
			// Create new line with updated type
			newLine := fmt.tprintf("%s%s :%s: %s", leadingWhitespace, record.name, newType, record.value)
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
	newContent := strings.join(newLines[:], "\n")
	writeSuccess := write_to_file(collectionPath, transmute([]byte)newContent, get_caller_location())
	if !writeSuccess{
	    make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
	    return success
	}else{
	    success = true
	}

	return success
}

//Used to ensure that the passed in records type is valid and if its shorthand assign the value as the longhand
//e.g if INT then assign INTEGER. Returns the type
//Remember to delete() the return value in the calling procedure
set_record_type :: proc(record: ^lib.Record) -> string {
    using lib

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
	return strings.clone(RecordDataTypesAsString[record.type])
}


//Returns the data type of the passed in record
get_record_type :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> ( string, bool) {
    using lib

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

	content := string(data)
	defer delete(content)

	clusters := strings.split(content, "},")
	defer delete(clusters)

	for c in clusters {
		//check for cluster
		if strings.contains(c, fmt.tprintf("cluster_name :identifier: %s", cluster.name)) {
			lines := strings.split(c, "\n")
			for line in lines {
				line := strings.trim_space(line)
				// Check if this line contains our record
				if strings.has_prefix(line, fmt.tprintf("%s :", record.name)) {
					// Split the line into parts using ":"
					parts := strings.split(line, ":")
					if len(parts) >= 2 {
					    success = true
						// Return the type of the record
						return strings.clone(strings.trim_space(parts[1])), success
					}
				}
			}
		}
	}

	return "", success
}

set_record_value ::proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> bool {
    using lib

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
	case RecordDataTypesAsString[.INTEGER]:
		record.type = .INTEGER
		valueAny, ok = CONVERT_RECORD_TO_INT(rValue)
		setValueOk = ok
		break
	case RecordDataTypesAsString[.FLOAT]:
		record.type = .FLOAT
		valueAny, ok = CONVERT_RECORD_TO_FLOAT(rValue)
		setValueOk = ok
		break
	case RecordDataTypesAsString[.BOOLEAN]:
		record.type = .BOOLEAN
		valueAny, ok = CONVERT_RECORD_TO_BOOL(rValue)
		setValueOk = ok
		break
	case RecordDataTypesAsString[.STRING]:
		record.type = .STRING
		valueAny = append_qoutations(rValue)
		setValueOk = true
		break
	case RecordDataTypesAsString[.CHAR]:
		record.type = .CHAR
		if len(rValue) != 1 {
			setValueOk = false
			fmt.println("Failed to set record value")
			fmt.printfln(
				"Value of type %s%s%s must be a single character",
				utils.BOLD_UNDERLINE,
				recordType,
				utils.RESET,
			)
		} else {
			valueAny = append_single_qoutations__string(rValue)
			setValueOk = true
		}
		break
	case RecordDataTypesAsString[.INTEGER_ARRAY]:
		record.type = .INTEGER_ARRAY
		verifiedValue := VERIFY_ARRAY_VALUES(RecordDataTypesAsString[.INTEGER_ARRAY], rValue)
		if !verifiedValue {
			fmt.printfln(
				"Invalid value given. Must be an array of Type: %sINTEGER%s",
				utils.BOLD_UNDERLINE,
				utils.RESET,
			)
			return false
		}
		intArrayValue, ok := CONVERT_RECORD_TO_INT_ARRAY(rValue)
		valueAny = intArrayValue
		setValueOk = ok
		break
	case RecordDataTypesAsString[.FLOAT_ARRAY]:
		record.type = .FLOAT_ARRAY
		verifiedValue := VERIFY_ARRAY_VALUES(RecordDataTypesAsString[.FLOAT], rValue)
		if !verifiedValue {
			fmt.printfln(
				"Invalid value given. Must be an array of Type: %sFLOAT%s",
				utils.BOLD_UNDERLINE,
				utils.RESET,
			)
			return false
		}
		fltArrayValue, ok := CONVERT_RECORD_TO_FLOAT_ARRAY(rValue)
		valueAny = fltArrayValue
		setValueOk = ok
		break
	case RecordDataTypesAsString[.BOOLEAN_ARRAY]:
		record.type = .BOOLEAN_ARRAY
		verifiedValue := VERIFY_ARRAY_VALUES(RecordDataTypesAsString[.BOOLEAN_ARRAY], rValue)
		if !verifiedValue {
			fmt.printfln(
				"Invalid value given. Must be an array of Type: %BOOLEAN%s",
				utils.BOLD_UNDERLINE,
				utils.RESET,
			)
			return false
		}
		boolArrayValue, ok := CONVERT_RECORD_TO_BOOL_ARRAY(rValue)
		valueAny = boolArrayValue
		setValueOk = ok
		break
	case RecordDataTypesAsString[.STRING_ARRAY]:
		record.type = .STRING_ARRAY
		stringArrayValue, ok := CONVERT_RECORD_TO_STRING_ARRAY(rValue)
		valueAny = stringArrayValue
		setValueOk = ok
		break
	case RecordDataTypesAsString[.CHAR_ARRAY]:
		record.type = .CHAR_ARRAY
		charArrayValue, ok := CONVERT_RECORD_TO_CHAR_ARRAY(rValue)
		valueAny = charArrayValue
		setValueOk = ok
		break
	case RecordDataTypesAsString[.DATE_ARRAY]:
		record.type = .DATA_ARRAY
		dateArrayValue, ok := CONVERT_RECORD_TO_DATE_ARRAY(rValue)
		valueAny = dateArrayValue
		setValueOk = ok
		break
	case RecordDataTypesAsString[.TIME_ARRAY]:
		record.type = .TIME_ARRAY
		timeArrayValue, ok := CONVERT_RECORD_TO_TIME_ARRAY(rValue)
		valueAny = timeArrayValue
		setValueOk = ok
		break
	case RecordDataTypesAsString[.DATETIME_ARRAY]:
		record.type = .DATETIME_ARRAY
		dateTimeArrayValue, ok := CONVERT_RECORD_TO_DATETIME_ARRAY(rValue)
		valueAny = dateTimeArrayValue
		setValueOk = ok
		break
	case RecordDataTypesAsString[.DATE]:
		record.type = .DATE
		date, ok := CONVERT_RECORD_TO_DATE(rValue)
		if ok {
			valueAny = date
			setValueOk = ok
		}
		break
	case RecordDataTypesAsString[.TIME]:
		record.type = .TIME
		time, ok := CONVERT_RECORD_TO_TIME(rValue)
		if ok {
			valueAny = time
			setValueOk = ok
		}
		break
	case RecordDataTypesAsString[.DATETIME]:
		record.type = .DATETIME
		dateTime, ok := CONVERT_RECORD_TO_DATETIME(rValue)
		if ok {
			valueAny = dateTime
			setValueOk = ok
		}
		break
	case RecordDataTypesAsString[.UUID]:
		record.type = .UUID
		uuid, ok := CONVERT_RECORD_TO_UUID(rValue)
		if ok {
			valueAny = uuid
			setValueOk = ok
		}
		break
	case RecordDataTypesAsString[.UUID_ARRAY]:
		record.type = .UUID_ARRAY
		uuidArrayValue, ok := CONVERT_RECORD_TO_UUID_ARRAY(rValue)
		valueAny = uuidArrayValue
		setValueOk = ok
		break
	case RecordDataTypesAsString[.NULL]:
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
			fmt.tprintf(
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

	// Update the record in the file
	success := UPDATE_RECORD(file, cn, rn, valueAny)


	//Don't forget to free memory :) - Marshall Burns aka @SchoolyB
	delete(intArrayValue)
	delete(fltArrayValue)
	delete(boolArrayValue)
	delete(stringArrayValue)
	delete(charArrayValue)
	delete(dateArrayValue)
	delete(timeArrayValue)
	delete(dateTimeArrayValue)
	delete(uuidArrayValue)
	return success



    return success
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
