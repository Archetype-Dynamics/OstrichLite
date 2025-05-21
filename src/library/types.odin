package library

import "core:time"
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
//GENERAL TYPES START
OstrichLiteEngine:: struct{
    EngineRuntime: time.Duration,
    Server: OstrichLiteServer
    //more??
}
//GENERAL TYPES END

//DATA RELATED TYPES START
DataStructureTier :: enum {
    COLLECTION = 0,
    CLUSTER,
    RECORD,
}

CollectionType :: enum {
    STANDARD_PUBLIC = 0 ,
    BACKUP_PUBLIC,
    //Add more if needed
}

Collection :: struct {
    name: string,
    type: CollectionType,
    numberOfClusters: int,
    clusters: [dynamic]Cluster, //might not do this
    // size: int //Bytes??? or fileInfo.size???
}

Cluster :: struct {
    parent: Collection,
    name: string,
    id: i64,
    numberOfRecords: int,
    records: [dynamic]Record, //might not do this
    // size: int //in bytes??
}

Record :: struct{
    grandparent: Collection,
    parent: Cluster,
    id: i64,
    name,  value:string,
    type: RecordDataTypes
    // size:int //in bytes??
}

RecordDataTypes :: enum {
    INVALID = 0,
	NULL,
    CHAR,
    STR,
	STRING,
	INT,
	INTEGER,
	FLT,
	FLOAT,
	BOOL,
	BOOLEAN,
	DATE,
	TIME,
	DATETIME,
	UUID,
	CHAR_ARRAY,
	STR_ARRAY,
	STRING_ARRAY,
	INT_ARRAY,
	INTEGER_ARRAY,
	FLT_ARRAY,
	FLOAT_ARRAY,
	BOOL_ARRAY,
	BOOLEAN_ARRAY,
	DATE_ARRAY,
	TIME_ARRAY,
	DATETIME_ARRAY,
	UUID_ARRAY,
}

@(rodata)
RecordDataTypesStrings := [RecordDataTypes]string {
    .INVALID = "INVALID",
    .NULL = "NULL" ,
    .CHAR = "CHAR" ,
    .STR = "STR" ,
    .STRING = "STRING" ,
    .INT = "INT" ,
    .INTEGER = "INTEGER" ,
    .FLT = "FLT" ,
    .FLOAT = "FLOAT" ,
    .BOOL = "BOOL" ,
    .BOOLEAN = "BOOLEAN" ,
    .DATE = "DATE" ,
    .TIME = "TIME" ,
    .DATETIME = "DATETIME" ,
    .UUID = "UUID" ,
    .CHAR_ARRAY = "CHAR_ARRAY" ,
    .STR_ARRAY = "STR_ARRAY" ,
    .STRING_ARRAY = "STRING_ARRAY" ,
    .INT_ARRAY = "INT_ARRAY" ,
    .INTEGER_ARRAY = "INTEGER_ARRAY" ,
    .FLT_ARRAY = "FLT_ARRAY" ,
    .FLOAT_ARRAY = "FLOAT_ARRAY" ,
    .BOOL_ARRAY = "BOOL_ARRAY" ,
    .BOOLEAN_ARRAY = "BOOLEAN_ARRAY" ,
    .DATE_ARRAY = "DATE_ARRAY" ,
    .TIME_ARRAY = "TIME_ARRAY" ,
    .DATETIME_ARRAY = "DATETIME_ARRAY" ,
    .UUID_ARRAY = "UUID_ARRAY" ,
}

//DATA RELATED TYPES END


MetadataField :: enum {
    ENCRYPTION_STATE = 0,
    FILE_FORMAT_VERSION,
    PERMISSION,
    DATE_CREATION,
    DATE_MODIFIED,
    FILE_SIZE,
    CHECKSUM,
}


//SERVER RELATED START
OstrichLiteServer :: struct {
    port: int,
    //more??
}

HttpStatusCode :: enum{
    OK                         = 200,
	BAD_REQUEST   = 400,
	NOT_FOUND      = 404,
	SERVER_ERROR = 500,
}

HttpStatus :: struct {
    statusCode: HttpStatusCode,
    text: string
    //more??
}

HttpMethod :: enum {
    HEAD = 0,
    GET,
    POST,
    PUT,
    DELETE,
}

HttpMethodString := [HttpMethod]string{
    .HEAD = "HEAD",
    .GET    = "GET",
    .POST    = "POST",
    .PUT    = "PUT",
    .DELETE    = "DELETE",

}

RouteHandler ::proc(method,path:string, headers:map[string]string, params: ..string) -> (HttpStatus, string)

Route :: struct {
    method: HttpMethod,
    path: string,
    handler: RouteHandler
}

Router :: struct {
    routes: [dynamic]Route
}

//Cant find docs on #sparse.  No idea what it is but if it isn't here this wont work
HttpStatusText :: #sparse[HttpStatusCode]string {
	.OK                         = "OK",
	.BAD_REQUEST   = "Bad Request",
	.NOT_FOUND      = "Not Found",
	.SERVER_ERROR = "Internal Server Error",
}

ServerEvent :: struct {
	name:           string,
	description:    string,
	type:           ServerEventType,
	timestamp:      time.Time,
	isRequestEvent: bool,
	route:          Route,
	statusCode:     HttpStatusCode,
}


ServerEventType :: enum {
	ROUTINE = 0,
	WARNING,
	ERROR,
	CRITICAL_ERROR
}

//For error logging

//Type alias for source code location info
SourceCodeLocation::runtime.Source_Code_Location
#assert(SourceCodeLocation == runtime.Source_Code_Location)
