package server

import lib"../../library"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file contains all functions related to
            event logging on the server.
*********************************************************/

//creates a new server log file
@(cold, require_results)
create_server_log_file :: proc() -> bool {
    using lib

    success:= false

	serverLogFile, creationSuccess := os.open(SERVER_LOG_PATH,os.O_CREATE | os.O_RDWR,0o666,)
	if creationSuccess != 0 {
        make_new_err(.CANNOT_CREATE_FILE, get_caller_location())
	}else{
        success = true
	}
	os.close(serverLogFile)
	return success
}


//n - name
//d - description
//ty - type
//ti - time
//isReq - isRequestEvent
//p - path
//m - method
@(require_results)
make_new_server_event :: proc(n, d: string,ty: lib.ServerEventType,ti: time.Time,isReq: bool,p: string,m: lib.HttpMethod) -> ^lib.ServerEvent {
    using lib
	event := new(ServerEvent)
	event.name = n
	event.description = d
	event.type = ty
	event.timestamp = ti
	event.isRequestEvent = isReq
	event.route.path = p
	event.route.method = m
	return event
}

//Disabled this proc rather than removing it because unsure if will need in the future??? - Marshall
@(disabled=true)
print_server_event_information :: proc(event: ^lib.ServerEvent) {
    using lib
    using fmt

	println("Server Event Name: ", event.name)
	println("Server Event Description: ", event.description)
	println("Server Event Type: ", event.type)
	println("Server Event Timestamp: ", event.timestamp)
	println("Server Event is a request: ", event.isRequestEvent)

	if event.isRequestEvent == true {
		println("Path used in request event: ", event.route.path)
		println("Method used in request event: ", event.route.method)
	}

	println("\n")
}

//logs the data contained within the passed in event
@(require_results)
log_server_event :: proc(event: ^lib.ServerEvent) -> bool {
    using lib
    using fmt

    eventTriggered:= tprintfln("Server Event Triggered: '%s'",event.name)
    eventTime:= tprintfln("Server Event Time: '%v'", event.timestamp)
    eventDesc:= tprintfln("Server Event Description: '%s'", event.description)
    eventType:= tprintfln("Server Event Type: '%v'", event.type,)
    eventIsReq := tprintfln("Server Event is a Request Event: '%v'", event.isRequestEvent,)
    logMsg := strings.concatenate([]string{eventTriggered, eventTime, eventDesc, eventType, eventIsReq, })
    defer delete(logMsg)

	concatLogMsg, someVar: string
	defer delete(concatLogMsg)

	if event.isRequestEvent == true {
	    switch(event.route.method){
		case .HEAD:
            someVar = "HEAD"
            break
	    case .GET:
			someVar = "GET"
			break
		case .DELETE:
		    someVar =  "DELETE"
			break
		case .POST:
            someVar  = "POST"
            break
		case .PUT:
            someVar = "PUT"
            break
    	case .OPTIONS:
			someVar = "OPTIONS"
			break
	}

	    routePath:= tprintf("Server Event Route Path: '%s'\n", event.route.path,)
	    routeMethod:= tprintf("Server Event Route Method: '%s'\n", someVar)
	    concatLogMsg = strings.concatenate([]string{logMsg, routePath, routeMethod, "\n\n"})

	}

	logMessage := transmute([]u8)concatLogMsg

	serverEventLogFile, openSuccess := os.open(SERVER_LOG_PATH, os.O_APPEND | os.O_RDWR, 0o666,)
	defer os.close(serverEventLogFile)
	if openSuccess != 0 {
	    make_new_err(.CANNOT_OPEN_FILE, get_caller_location())
		return false
	}


	_, writeSuccess := os.write(serverEventLogFile, logMessage)
	if writeSuccess != 0 {
	    make_new_err(.CANNOT_WRITE_TO_FILE, get_caller_location())
		return false
	}else do return true
}