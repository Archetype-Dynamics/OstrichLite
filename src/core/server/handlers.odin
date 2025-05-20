package server

import lib "../../library"
import "core:fmt"
import "core:strings"

collectionName, clusterName, recordName:string


handle_get_request :: proc(method: lib.HttpMethod, path:string, headers: map[string]string) -> (lib.HttpStatus, string){
    using lib

    if method != .GET {
        return HttpStatus{statusCode = .BAD_REQUEST, text = HttpStatusText[.BAD_REQUEST]},
        "Method not allowed\n"
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
                    }, "//TODO: FETCH COLLECTION HERE"
                case 4:
                    collectionName = segments[1]
                    clusterName = segments[3]
                    return HttpStatus {
                        statusCode = .OK,
                        text = HttpStatusText[.OK]
                    }, "//TODO: FETCH CLUSTER HERE"
                case 6:
                    collectionName = segments[1]
                    clusterName = segments[3]
                    recordName = segments[5]
                    return HttpStatus {
                        statusCode = .OK,
                        text = HttpStatusText[.OK]
                    }, "//TODO: FETCH RECORD HERE"
        }
    case "version":
       	// version := utils.get_ost_version()
        return HttpStatus {
            statusCode = .OK,
            text = HttpStatusText[.OK],
        }, "TODO: FETCH OstrichLite VERSION HERE" //  fmt.tprintf("OstrichDB Version: %s\n", version)


        // ADD MORE ENDPOINTS HERE
    }

    return HttpStatus{statusCode = .NOT_FOUND, text = HttpStatusText[.NOT_FOUND]},
    "Not Found\n"
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
	return split(trim_prefix(path, "/"), "/")
}
