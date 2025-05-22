package server

import lib "../../library"
import "core:fmt"
import "core:strings"
import "../engine/data"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains logic for handling requests from the client.
            All handlers expected to follow the `RouteHandler` procedure signature
            found in types.odin Note: Unstable and not fully implemented.
*********************************************************/


//This proc is a great template on how the remaining request handling procedure will generally work
//Note: See all comments to help understand flow of this proc
handle_get_request :: proc(method: lib.HttpMethod, path:string, headers: map[string]string) -> (^lib.HttpStatus, string){
    using lib
    using data

    //If by chance a programmer passes the wrong method while trying to call this proc the request over the server wont work :)
    if method != .GET {
        newHTTPStatus:= make_new_http_status(.BAD_REQUEST, HttpStatusText[.BAD_REQUEST] )
        return newHTTPStatus, "Method not allowed\n"
    }

    //Split a url(path) into segments
    segments:= split_path_into_segments(path)
    defer delete(segments)

    //Get the numbe of segments
    numberOfSegments := len(segments)


    switch(segments[0]){
    case "c": //endpoint is ATLEAST targeting a collection

        //Allocate mem for new data structures
        newCollection:= make_new_collection("", .STANDARD_PUBLIC)
        newCluster:= make_new_cluster(newCollection,"")
        newRecord:= make_new_record(newCollection, newCluster, "")

        //The less memory leaks the better :)
        defer free(newCollection)
        defer free(newCluster)
        defer free(newRecord)

        switch(numberOfSegments){
                case 2: //if the path is only targeting a collection e.g: localhost:8042/c/myCooldb1

                    //Assign key information regarding the target collection
                    newCollection.name = segments[1]
                    newHTTPStatus:= make_new_http_status(.OK, HttpStatusText[.OK]) //prepare an OK status
                    value, fetchCollectionSuccess:=fetch_collection(newCollection) //try to do work
                    if !fetchCollectionSuccess{ //if work fails, free the OK status, make a SERVER_ERROR status and return
                        free(newHTTPStatus)
                        newHTTPStatus := make_new_http_status(.SERVER_ERROR, HttpStatusText[.SERVER_ERROR])
                        return newHTTPStatus, "OstrichLite Server Error"
                    }
                    return newHTTPStatus, value
                case 4: //path is targeting a cluster

                    //Assign key information regarding the target collection and cluster. Note: Recommed doing smallest data structure to largest for less confusion
                    newCluster.name = segments[3]
                    newCluster.parent = newCollection^
                    append(&newCollection.clusters, newCluster^)
                    newCollection.name =segments[1]
                    newHTTPStatus:= make_new_http_status(.OK, HttpStatusText[.OK]) //prepare an OK status
                    value, fetchClusterSuccess:= fetch_cluster(newCollection, newCluster) //try to do work
                    if !fetchClusterSuccess{ //if work fails, free the OK status, make a SERVER_ERROR status and return
                        free(newHTTPStatus)
                        newHTTPStatus:= make_new_http_status(.SERVER_ERROR, HttpStatusText[.SERVER_ERROR])
                        return newHTTPStatus, "OstrichLite Server Error"
                    }
                    return newHTTPStatus, value

                case 6: //path is targeting a record

                     //Assign key information regarding the target collection, cluster, and record. Note: Recommed doing smallest data structure to largest for less confusion
                     newRecord.grandparent = newCollection^
                     newRecord.parent = newCluster^
                     newRecord.name = segments[5]
                     append(&newCluster.records, newRecord^)

                     newCluster.parent = newCollection^
                     newCluster.name = segments[3]
                     append(&newCollection.clusters, newCluster^)

                     newCollection.name = segments[1]

                    newHTTPStatus:= make_new_http_status(.OK, HttpStatusText[.OK]) //prepare an OK status
                    record, fetchRecordSuccess:=fetch_record(newCollection, newCluster, newRecord) //try to do work
                    if !fetchRecordSuccess{ //if work fails, free the OK status, make a SERVER_ERROR status and return
                        free(newHTTPStatus)
                        newHTTPStatus:= make_new_http_status(.SERVER_ERROR, HttpStatusText[.SERVER_ERROR])
                        return newHTTPStatus, "OstrichLite Server Error"
                    }
                    //Todo: The above fetch_Record proc call returns a record, so we can technically return record.name or .type or .value. Guess it depends???
                    return newHTTPStatus, record.value
        }
    case "version":
       	version := get_ost_version()
        newHTTPStatus:= make_new_http_status(.OK, HttpStatusText[.OK])
        return newHTTPStatus, fmt.tprintf("OstrichDB Version: %s\n", version)


        //Add more GET method endpoints here when need
    }


    newHTTPStatus:= make_new_http_status(.NOT_FOUND, HttpStatusText[.NOT_FOUND])
    return newHTTPStatus, "Not Found\n"
}



handle_delete_route :: proc(method: lib.HttpMethod, path:string, headers: map[string]string) -> (lib.HttpStatus, string){
    using lib

    if method != .DELETE {
		return HttpStatus{statusCode = .BAD_REQUEST, text = HttpStatusText[.BAD_REQUEST]},
			"Invalid method\n"
	}


    segments:= split_path_into_segments(path)
    defer delete(segments)

    numberOfSegments := len(segments)

    switch(segments[0]){
    case "c": //endpoint target ATLEAST a collection
        switch(numberOfSegments){
                case 2:
                    collectionName = segments[1]
                    return HttpStatus {
                        statusCode = .OK,
                        text = HttpStatusText[.OK]
                    }, "//TODO: ERASE COLLECTION HERE"
                case 4:
                    collectionName = segments[1]
                    clusterName = segments[3]
                    return HttpStatus {
                        statusCode = .OK,
                        text = HttpStatusText[.OK]
                    }, "//TODO: ERASE CLUSTER HERE"
                case 6:
                    collectionName = segments[1]
                    clusterName = segments[3]
                    recordName = segments[5]
                    return HttpStatus {
                        statusCode = .OK,
                        text = HttpStatusText[.OK]
                    }, "//TODO: ERASE RECORD HERE"
        }
    }

    return HttpStatus{statusCode = .NOT_FOUND, text = HttpStatusText[.NOT_FOUND]},
    "Not Found\n"
}

//Todo: Add POST request handler


//Helper used to parse a query string into a map
parse_query_string :: proc(query: string) -> map[string]string {
    using strings

	params := make(map[string]string)
	pairs := split(query, "&")
	for pair in pairs {
		keyValue := split(pair, "=")
		if len(keyValue) == 2 {
			params[keyValue[0]] = keyValue[1]
		}
	}
	return params
}


//Helper to split a path by the '/'
split_path_into_segments :: proc(path: string) -> []string {
    using strings

	return split(trim_prefix(path, "/"), "/")
}
