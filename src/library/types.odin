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
    children: [dynamic]Cluster, //might not do this
    // size: int //Bytes??? or fileInfo.size???
}

Cluster :: struct {
    parent: Collection,
    name: string,
    id: i64,
    numberOfRecords: int,
    children: [dynamic]Record, //might not do this
    // size: int //in bytes??
}

Record :: struct{
    name, type, value:string
    // size:int //in bytes??
}

//DATA RELATED TYPES END


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
