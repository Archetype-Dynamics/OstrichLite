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

StandardUserCredential :: struct {
	Value:  string, //username
	Length: int, //length of the username
}

SpecialUserCredential :: struct {
	valAsBytes: []u8,
	valAsStr:   string,
}

User :: struct {
	user_id:        i64,
	role:           StandardUserCredential,
	username:       StandardUserCredential,
	password:       StandardUserCredential,
	salt:           SpecialUserCredential,
	hashedPassword: SpecialUserCredential, //this is the hashed password without the salt
	store_method:   int,
	m_k:            SpecialUserCredential, //master key
}

OstrichLiteEngine:: struct{
    EngineRuntime: time.Duration,
    Server: Server
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
Server :: struct {
    port: int,
    //more??
}

HttpStatusCode :: enum{
    //2xx codes
    OK                  = 200,
    CREATE              = 201,
    NO_CONTENT          = 204,
    PARTIAL_CONTENT     = 206,
    //3xx codes
    MOVED_PERMANENTLY   = 301,
    FOUND               = 302,
    NOT_MODIFIED        = 304,
    //4xx codes
    BAD_REQUEST         = 400,
    UNAUTHORIZED        = 401,
    FORBIDDEN           = 403,
    NOT_FOUND           = 404,
    METHOD_NOT_ALLOWED  = 405,
    CONFLICT            = 409,
    PAYLOAD_TOO_LARGE   = 413,
    UNSUPPORTED_MEDIA   = 415,
    TOO_MANY_REQUESTS   = 429,
    //5xx codes
    SERVER_ERROR        = 500,
    NOT_IMPLEMENTED     = 501,
    BAD_GATEWAY         = 502,
    SERVICE_UNAVAILABLE = 503,
    GATEWAY_TIMEOUT     = 504,
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
    OPTIONS,
}

HttpMethodString := [HttpMethod]string{
    .HEAD = "HEAD",
    .GET    = "GET",
    .POST    = "POST",
    .PUT    = "PUT",
    .DELETE    = "DELETE",
    .OPTIONS = "OPTIONS",
}

//All request handler procecures which are located in in handlers.odin need to follow this signature.
//Note: 'args'  are only passed when makeing a POST or GET request
RouteHandler ::proc(method: HttpMethod,path:string, headers:map[string]string, args:[]string) -> (^HttpStatus, string)

Route :: struct {
    method: HttpMethod,
    path: string,
    handler: RouteHandler
}

Router :: struct {
    routes: [dynamic]Route
}

//Cant find docs on #sparse. Just used the compilers error message if you removed it
HttpStatusText :: #sparse[HttpStatusCode]string {
    //2xx codes
    .OK                  = "OK",
    .CREATE              = "Created",
    .NO_CONTENT          = "No Content",
    .PARTIAL_CONTENT     = "Partial Content",
    //3xx codes
    .MOVED_PERMANENTLY   = "Moved Permanently",
    .FOUND               = "Found",
    .NOT_MODIFIED        = "Not Modified",
    //4xx codes
    .BAD_REQUEST         = "Bad Request",
    .UNAUTHORIZED        = "Unauthorized",
    .FORBIDDEN           = "Forbidden",
    .NOT_FOUND           = "Not Found",
    .METHOD_NOT_ALLOWED  = "Method Not Allowed",
    .CONFLICT            = "Conflict",
    .PAYLOAD_TOO_LARGE   = "Payload Too Large",
    .UNSUPPORTED_MEDIA   = "Unsupported Media Type",
    .TOO_MANY_REQUESTS   = "Too Many Requests",
    //5xx codes
    .SERVER_ERROR        = "Internal Server Error",
    .NOT_IMPLEMENTED     = "Not Implemented",
    .BAD_GATEWAY         = "Bad Gateway",
    .SERVICE_UNAVAILABLE = "Service Unavailable",
    .GATEWAY_TIMEOUT     = "Gateway Timeout",
}

ServerSession :: struct {
    Id:                 i64,
    user:                     User,
    start_timestamp:     time.Time,
    end_timestamp:      time.Time,
    total_runtime:          time.Duration
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

QueryToken :: enum{
    INVALID = 0,
    //Command tokens
    NEW,
    ERASE,
    FETCH,
    RENAME,
    SET,
    PURGE,
    //parameter tokens
    TO,
    OF_TYPE,
    WITH,
    //Create and add more???
}

QueryTokenString :: #partial[QueryToken]string{
    .NEW = "NEW",
    .ERASE = "ERASE",
    .RENAME = "RENAME",
    .FETCH = "FETCH",
    .SET = "SET",
    .PURGE = "PURGE",
    .TO = "TO",
    .OF_TYPE = "OF_TYPE",
    .WITH = "WITH",
}

TokenStrings :: #partial[QueryToken]string{
    //command token strings
    .NEW = "NEW",
    .ERASE = "ERASE",
    .FETCH = "FETCH",
    .RENAME = "RENAME",
    .SET = "SET",
    .PURGE = "PURGE",
    //parameter token strings
    .TO = "TO",
    .OF_TYPE = "OF_TYPE",
    .WITH = "WITH",

}

Query :: struct {
    CommandToken : QueryToken,
    LocationToken: [dynamic]string,
    ParameterToken: map[string]string,
    isChained: bool,
    rawInput: string
}

QueryParserState :: enum {
    ExpectingCommandToken = 0,
    ExpectingParameterToken,
    ExpectingValue
}