package library

import "core:fmt"
import "core:os"
import "core:strings"
import "base:runtime"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file contains all the logic for interacting with
            collections within the OstrichLite engine.
*********************************************************/

ErrorType :: enum {
	NO_ERROR,
	//General File Errors
	CANNOT_CREATE_FILE,
	CANNOT_OPEN_FILE,
	CANNOT_READ_FILE,
	CANNOT_UPDATE_FILE, //rarely used. see 1 usage in metadata.odin
	CANNOT_WRITE_TO_FILE,
	CANNOT_CLOSE_FILE,
	CANNOT_DELETE_FILE,
	FILE_ALREADY_EXISTS,
	//Directory Errors
	CANNOT_OPEN_DIRECTORY,
	CANNOT_READ_DIRECTORY,
	CANNOT_CREATE_DIRECTORY,
	//Collection errors
	CANNOT_CREATE_COLLECTION,
	CANNOT_APPEND_METADATA,
	COLLECTION_ALREADY_EXISTS,
	//Add more???
	//Cluster Errors
	INVALID_CLUSTER_STRUCTURE,
	CLUSTER_ALREADY_EXISTS,
	CANNOT_CREATE_CLUSTER,
	CANNOT_FIND_CLUSTER,
	CANNOT_DELETE_CLUSTER,
	CANNOT_READ_CLUSTER,
	CANNOT_UPDATE_CLUSTER,
	CANNOT_APPEND_CLUSTER,
	CLUSTER_DOES_NOT_EXIST_IN_CLUSTER,
	CLUSTER_ALREADY_EXISTS_IN_COLLECTION,
	//Record Errors
	INVALID_RECORD_DATA,
	CANNOT_CREATE_RECORD,
	CANNOT_FIND_RECORD,
	CANNOT_DELETE_RECORD,
	CANNOT_READ_RECORD,
	CANNOT_UPDATE_RECORD,
	CANNOT_APPEND_RECORD,
	RECORD_DOES_NOT_EXIST_IN_CLUSTER,
	RECORD_ALREADY_EXISTS_IN_CLUSTER,
	//Input Error
	CANNOT_READ_INPUT,
	//Signup Errors
	USERNAME_ALREADY_EXISTS,
	INVALID_USERNAME,
	PASSWORD_TOO_SHORT,
	PASSWORD_TOO_LONG,
	WEAK_PASSWORD,
	PASSWORDS_DO_NOT_MATCH,
	//Auth Errors
	INCORRECT_USERNAME_ENTERED,
	INCORRECT_PASSWORD_ENTERED,
	ENTERED_USERNAME_NOT_FOUND,
	//command ERRORS
	INCOMPLETE_COMMAND,
	INVALID_COMMAND,
	COMMAND_TOO_LONG, //??? idk
	CANNOT_PURGE_HISTORY,
	//Data Integrity Errors
	FILE_SIZE_TOO_LARGE,
	FILE_FORMAT_NOT_VALID,
	FILE_FORMAT_VERSION_NOT_SUPPORTED,
	CLUSTER_IDS_NOT_VALID,
	INVALID_CHECKSUM,
	INVALID_DATA_TYPE_FOUND,
	INVALID_VALUE_FOR_EXPECTED_TYPE,


	//Miscellaneous
	INVALID_INPUT,
}

Error :: struct {
	type:      ErrorType,
	message:   string, //The message that the error displays/logs
	location:  runtime.Source_Code_Location
}

ErrorMessage := [ErrorType]string {
	.NO_ERROR                          = "No error occurred",
	//General File Errors
	.CANNOT_CREATE_FILE                = "Failed to create file",
	.CANNOT_OPEN_FILE                  = "Failed to open file",
	.CANNOT_READ_FILE                  = "Failed to read file contents",
	.CANNOT_UPDATE_FILE                = "Failed to update file",
	.CANNOT_WRITE_TO_FILE              = "Failed to write to file",
	.CANNOT_CLOSE_FILE                 = "Failed to close file",
	.CANNOT_DELETE_FILE                = "Failed to delete file",
	.FILE_ALREADY_EXISTS               = "File already exists",
	//Directory Errors
	.CANNOT_OPEN_DIRECTORY             = "Failed to open directory",
	.CANNOT_READ_DIRECTORY             = "Failed to read directory contents",
	.CANNOT_CREATE_DIRECTORY           = "Failed to create directory",
	//Collection errors
	.CANNOT_CREATE_COLLECTION          = "Failed to create collection",
	.CANNOT_APPEND_METADATA            = "Failed to append metadata header to collection",
	.COLLECTION_ALREADY_EXISTS         = "Collection already exists",
	//Cluster Errors
	.INVALID_CLUSTER_STRUCTURE         = "Invalid cluster structure detected",
	.CLUSTER_ALREADY_EXISTS            = "Cluster already exists within collection",
	.CANNOT_CREATE_CLUSTER             = "Failed to create cluster",
	.CANNOT_FIND_CLUSTER               = "Failed to find cluster",
	.CANNOT_DELETE_CLUSTER             = "Failed to delete cluster",
	.CANNOT_READ_CLUSTER               = "Failed to read cluster",
	.CANNOT_UPDATE_CLUSTER             = "Failed to update cluster",
	.CANNOT_APPEND_CLUSTER             = "Failed to append cluster",
	.CLUSTER_DOES_NOT_EXIST_IN_CLUSTER            = "Specified cluster does not exist",
	.CLUSTER_ALREADY_EXISTS_IN_COLLECTION = "Cluster already exists in collection",
	//Record Errors
	.INVALID_RECORD_DATA               = "Invalid record data",
	.CANNOT_CREATE_RECORD              = "Failed to create record",
	.CANNOT_FIND_RECORD                = "Failed to find record",
	.CANNOT_DELETE_RECORD              = "Failed to delete record",
	.CANNOT_READ_RECORD                = "Failed to read record",
	.CANNOT_UPDATE_RECORD              = "Failed to update record",
	.CANNOT_APPEND_RECORD              = "Failed to append record to cluster",
	.RECORD_DOES_NOT_EXIST_IN_CLUSTER = "Record does not exist in cluster",
	.RECORD_ALREADY_EXISTS_IN_CLUSTER  = "Record already exists in cluster",
	//Miscellaneous Errors
	.CANNOT_READ_INPUT                 = "Failed to read input",
	.USERNAME_ALREADY_EXISTS           = "Username already exists",
	.INVALID_USERNAME                  = "Invalid username format",
	.PASSWORD_TOO_SHORT                = "Password is too short",
	.PASSWORD_TOO_LONG                 = "Password is too long",
	.WEAK_PASSWORD                     = "Password is too weak",
	.PASSWORDS_DO_NOT_MATCH            = "Passwords do not match",
	.INCORRECT_USERNAME_ENTERED        = "Incorrect username entered",
	.INCORRECT_PASSWORD_ENTERED        = "Incorrect password entered",
	.ENTERED_USERNAME_NOT_FOUND        = "Username not found",
	.INCOMPLETE_COMMAND                = "Incomplete command",
	.INVALID_COMMAND                   = "Invalid command",
	.COMMAND_TOO_LONG                  = "Command exceeds maximum length",
	.CANNOT_PURGE_HISTORY              = "Failed to purge user history cluster",
	.FILE_SIZE_TOO_LARGE               = "Collection file size exceeds maximum limit",
	.FILE_FORMAT_NOT_VALID             = "Invalid collection file format",
	.FILE_FORMAT_VERSION_NOT_SUPPORTED = "Collection file format version is not supported",
	.CLUSTER_IDS_NOT_VALID             = "Cluster IDs in collection do not match valid cluster IDs",
	.INVALID_CHECKSUM                  = "Checksum mismatch - file may be corrupted",
	.INVALID_DATA_TYPE_FOUND           = "Invalid data type found in collection",
	.INVALID_VALUE_FOR_EXPECTED_TYPE   = "Invalid value provided for expected type",
	.INVALID_INPUT                     = "Invalid input",
}

get_caller_location :: proc(location:= #caller_location) -> SourceCodeLocation {
    return location
}

new_err :: proc(type: ErrorType, message: string, location: SourceCodeLocation) -> Error {
	return Error{type = type, message = message, location = location}
}

throw_err :: proc(err: ^Error) -> int {
		fmt.printfln("%s%s[ERROR ERROR ERROR ERROR]%s", RED, BOLD, RESET)
		fmt.printfln(
			"ERROR%s occured in...\nFile: [%s%s%s]\nOstrichDB Procedure: [%s%s%s] @ Line: [%s%d%s]\nInternal Error Type: %s[%v]%s\nError Message: [%s%s%s]",
			RESET,
			BOLD,
			err.location.file_path,
			RESET,
			BOLD,
			err.location.procedure,
			RESET,
			BOLD,
			err.location.line,
			RESET,
			BOLD,
			err.type,
			RESET,
			BOLD,
			err.message,
			RESET,
		)
		return 1
}

//allows for more customization of error messages.
//the custom err message that is passed is the same as the err message in the print statement
throw_custom_err :: proc(err: Error, custom_message: string) -> int {
		fmt.printfln("%s%s[ERROR ERROR ERROR ERROR]%s", RED, BOLD, RESET)
		fmt.printfln(
			"ERROR%s occured in procedure: [%s%s%s]\nInternal Error Type: %s[%v]%s\nError Message: [%s%s%s]",
			RESET,
			BOLD,
			err.location.procedure,
			RESET,
			BOLD,
			err.type,
			RESET,
			BOLD,
			custom_message,
			RESET,
		)
		return 1
}



//Hanles all error related shit, just pass it the two args and you are good. - Marshall
make_new_err :: proc(type:ErrorType, location:SourceCodeLocation){
    message:= ErrorMessage[type]

    error:= new(Error)
    error.type = type
    error.message = message
    error.location = location

    throw_err(error)
    log_err(fmt.tprintf("%s", error.message), location)


    free(error)
}