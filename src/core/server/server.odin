package server

import lib"../../library"
import "core:c/libc"
import "core:fmt"
import "core:net"
import "core:os"
import "core:thread"
import "core:time"
// import "../nlp"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
           Contains logic for handling incoming requests to the OstrichLite server.
           Currently unstable and not fully implemented.
*********************************************************/



@(private)
isRunning := true

//The isAutoServing flag is added for NLP. Auto serving will be set to true by default.
start_ostrich_server :: proc(server: ^lib.Server) -> int {
	using lib

	createdSuccess:=create_server_log_file()
	if !createdSuccess{
	    return -1
	}
	isRunning = true


	//TODO: need to find a way in which the user will be created before the engine starts
	//Temp fix is to just create a new User, will delete later
	user:= new(User)
	defer free(user)

	newServerSession:= make_new_server_session(user)
	defer free(newServerSession)

	router := make_new_router()
	defer free(router)


	initializedServerStartEvent := make_new_server_event(
		"Server Session Start",
		"OstrichDB Server started",
		ServerEventType.ROUTINE,
		newServerSession.start_timestamp,
		false,
		"",
		nil,
	)
	// print_server_event_information(initializedServerStartEvent)





	//OstrichDB GET version static route and server logging
	add_route_to_router(router, .GET, "/version", handle_get_request)
	versionRouteEvent := make_new_server_event(
		"Add Route",
		"Added '/version' static GET route to router",
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(versionRouteEvent)
	// print_server_event_information(versionRouteEvent)

	// HEAD, POST, GET, DELETE dynamic routes for collections as well as server logging
	add_route_to_router(router, .HEAD, C_DYNAMIC_BASE, HANDLE_HEAD_REQUEST)
	addHeadColRoute := make_new_server_event(
		"Add Route",
		give_description("HEAD",C_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addHeadColRoute)
	// print_server_event_information(addHeadColRoute)

	add_route_to_router(router, .POST, C_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	addPostColRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.POST],C_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addPostColRoute)
	// print_server_event_information(addPostColRoute)

	add_route_to_router(router, .GET, C_DYNAMIC_BASE, handle_get_request)
	addGetColRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.GET],C_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addGetColRoute)
	// print_server_event_information(addGetColRoute)

	add_route_to_router(router, .DELETE, C_DYNAMIC_BASE, HANDLE_DELETE_REQUEST)
	addDeleteColRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.DELETE],C_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addDeleteColRoute)
	// print_server_event_information(addDeleteColRoute)


	// HEAD, POST, GET, DELETE dynamic routes for clusters as well as server logging
	add_route_to_router(router, .HEAD, CL_DYNAMIC_BASE, HANDLE_HEAD_REQUEST)
	addHeadCluRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.HEAD],CL_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addHeadCluRoute)
	// print_server_event_information(addHeadCluRoute)

	add_route_to_router(router, .POST, CL_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	addPostCluRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.POST],CL_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addPostCluRoute)
	// print_server_event_information(addPostCluRoute)

	add_route_to_router(router, .GET, CL_DYNAMIC_BASE, handle_get_request)
	addGetCluRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.GET],CL_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addGetCluRoute)
	print_server_event_information(addGetCluRoute)

	add_route_to_router(router, .DELETE, CL_DYNAMIC_BASE, HANDLE_DELETE_REQUEST)
	addDeleteCluRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.DELETE],CL_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addDeleteCluRoute)
	// print_server_event_information(addDeleteCluRoute)


	// HEAD, POST, GET, DELETE dynamic routes for clusters as well as server logging
	add_route_to_router(router, .HEAD, R_DYNAMIC_BASE, HANDLE_HEAD_REQUEST)
	addHeadRecRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.HEAD],R_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addDeleteCluRoute)
	// print_server_event_information(addHeadRecRoute)

	add_route_to_router(router, .POST, R_DYNAMIC_TYPE_QUERY, HANDLE_POST_REQUEST)
	addPostRecRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.POST],R_DYNAMIC_TYPE_QUERY),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addDeleteCluRoute)
	// print_server_event_information(addPostRecRoute)

	add_route_to_router(router, .PUT, R_DYNAMIC_TYPE_VALUE_QUERY, HANDLE_PUT_REQUEST)
	addPutRecRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.PUT],R_DYNAMIC_TYPE_VALUE_QUERY),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addPutRecRoute)
	// print_server_event_information(addPutRecRoute)

	add_route_to_router(router, .GET, R_DYNAMIC_BASE, handle_get_request)
	addGetRecRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.GET],R_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addGetRecRoute)
	// print_server_event_information(addGetRecRoute)

	add_route_to_router(router, .DELETE, R_DYNAMIC_BASE, HANDLE_DELETE_REQUEST)
	addDeleteRecRoute := make_new_server_event(
		"Add Route",
		give_description(HttpMethodString[.DELETE],R_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	free(addDeleteRecRoute)
	// print_server_event_information(addDeleteRecRoute)



	// POST & GET dynamic routes for collections, clusters and records
	add_route_to_router(router, .POST, BATCH_C_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchColPostRoute:= make_new_server_event("Add Route",
				give_description(HttpMethodString[.POST],BATCH_C_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
		free(addBatchColPostRoute)
		// print_server_event_information(addBatchColPostRoute)

	add_route_to_router(router, .POST, BATCH_CL_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchCluPostRoute:= make_new_server_event("Add Route",
				give_description(HttpMethodString[.POST],BATCH_CL_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
		free(addBatchCluPostRoute)
		// print_server_event_information(addBatchCluPostRoute)

	add_route_to_router(router, .POST, BATCH_R_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchRPostRoute:= make_new_server_event("Add Route",
				give_description(HttpMethodString[.POST],BATCH_R_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
		free(addBatchRPostRoute)
		// print_server_event_information(addBatchRPostRoute)

	add_route_to_router(router, .GET, BATCH_C_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchColGetRoute:= make_new_server_event("Add Route",
				give_description(HttpMethodString[.GET],BATCH_C_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
		free(addBatchColGetRoute)
		// print_server_event_information(addBatchColGetRoute)

	add_route_to_router(router, .GET, BATCH_CL_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchCluGetRoute:= make_new_server_event("Add Route",
				give_description(HttpMethodString[.GET],BATCH_CL_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
		free(addBatchCluGetRoute)
		// print_server_event_information(addBatchCluGetRoute)

	add_route_to_router(router, .GET, BATCH_R_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchRecGetRoute:= make_new_server_event("Add Route",
				give_description(HttpMethodString[.GET],BATCH_R_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
		free(addBatchRecGetRoute)
		// print_server_event_information(addBatchRecGetRoute)


	//Assign the first usable OstrichDB port. Default is set to 8042 but might be taken
	usablePort:= check_if_port_is_free(ServerPorts)
    for p in ServerPorts {
       if p != usablePort{
               config.port = usablePort
               break
       }
    }

	//Create a new endpoint to listen on
	endpoint := net.Endpoint{net.IP4_Address{0, 0, 0, 0}, config.port} //listen on all interfaces


	// Creates and listens on a TCP socket
	listen_socket, listen_err := net.listen_tcp(endpoint, 5)
	if listen_err != nil {
		fmt.println("Error listening on socket: ", listen_err)
		return -1
	}


	//Start a thread to handle user input for killing the server
	thread.run(HANDLE_SERVER_KILL_SWITCH)
	defer net.close(net.TCP_Socket(listen_socket))

	fmt.printf(
		"OstrichDB server listening on port: %s%d%s\n",
		utils.BOLD_UNDERLINE,
		config.port,
		utils.RESET,
	)
	//Main server loop
	for isRunning {
		//update the session runtime periodically to check against the limit
		newServerSession.end_timestamp = time.now()
		newServerSession.total_runtime = time.diff(newServerSession.start_timestamp, newServerSession.end_timestamp)
		result:=check_id_server_session_limi_met(newServerSession)
		if result  {
		    fmt.printfln("%sWARNING:%s Maximum server session time of 24 hours reached. Shutting down server...", utils.YELLOW, utils.RESET)
		    isRunning = false
		    // Ping each possible OstrichDB port and if its running kill it
		    for port in ServerPorts {
		        portCString := strings.clone_to_cstring(fmt.tprintf("nc -zv localhost %d", port))
		        libc.system(portCString)
		    }
		    break
		}

		fmt.println("Waiting for new connection...")
		client_socket, remote_endpoint, accept_err := net.accept_tcp(listen_socket)

		if accept_err != nil {
			fmt.println("Error accepting connection: ", accept_err)
			return -1
		}
		handle_connection(client_socket)
	}
	newServerSession.end_timestamp = time.now()
	newServerSession.total_runtime = time.diff(newServerSession.start_timestamp, newServerSession.end_timestamp)
	fmt.println("Server stopped successfully")
	fmt.println("Total server session runtime time was: ", newServerSession.total_runtime)
	//Destroy the session
	free(newServerSession)
	return 0
}

//Tells the server what to do when upon accepting a connection
handle_connection :: proc(socket: net.TCP_Socket) {
    using lib

	defer net.close(socket)
	buf: [1024]byte
	fmt.println("Connection handler started")

	for {
		fmt.println("Waiting to receive data...")
		bytesRead, read_err := net.recv(socket, buf[:])

		if read_err != nil {
			fmt.println("Error reading from socket:", read_err)
			return
		}
		if bytesRead == 0 {
			fmt.println("Connection closed by client")
			return
		}


		// Parse incoming request
		parsedMethod, path, headers := parse_http_request(buf[:bytesRead])

		// Create response headers
		responseHeaders := make(map[string]string)
		responseHeaders["Content-Type"] = "text/plain"
		responseHeaders["Servesr"] = "OstrichDB"

       defer delete(responseHeaders)

       mthd:HttpMethod

       switch(parsedMethod) {
       case "HEAD":
           mthd = .HEAD
           break
       case "GET":
           mthd = .GET
           break
       case "POST":
           mthd = .POST
           break
       case "PUT":
           mthd = .PUT
           break
       case "DELETE":
           mthd = .DELETE
           break
       }

       // Handle the request using router
       status, responseBody := HANDLE_HTTP_REQUEST(router, parsedMethod, path, headers)
       handleRequestEvent := make_new_server_event(
           "Attempt Request",
           "Attempting to handle request made over the server",
           types.ServerEventType.ROUTINE,
           time.now(),
           true,
           path,
           mthd,
       )

       // print_server_event_information(handleRequestEvent)
       eventLogSuccess:=log_server_event(handleRequestEvent)
       if !eventLogSuccess do continue //TODO: throw error and or close server here instead of skipping over it???
       free(handleRequestEvent)


       // Build and send response
       newHTTPStatus:= make_new_http_status()
       response := BUILD_HTTP_RESPONSE(status, responseHeaders, responseBody)
       buildResponseEvent := make_new_server_event(
           "Build Response",
           "Attempting to build a response for the request",
           types.ServerEventType.ROUTINE,
           time.now(),
           false,
           path,
           mthd,
       )
       print_server_event_information(buildResponseEvent)
       log_server_event(buildResponseEvent)

       if len(response) == 0 {
           buildResponseFailEvent := make_new_server_event(
               "Failed Reponse Build",
               "Failed to build a response",
               types.ServerEventType.WARNING,
               time.now(),
               false,
               path,
               mthd,
           )
           print_server_event_information(buildResponseFailEvent)
           log_server_event(buildResponseFailEvent)
       }

       _, write_err := net.send(socket, response)
       writeResponseToSocket := make_new_server_event(
           "Write Respone To Socket",
           "Attempting to write a response to the socket",
           types.ServerEventType.ROUTINE,
           time.now(),
           false,
           path,
           mthd,
       )

       print_server_event_information(writeResponseToSocket)
       log_server_event(writeResponseToSocket)

       if write_err != nil {
           writeResponseToSocketFail := make_new_server_event(
               "Failed To Write To Socket",
               "Failed to write a response to the socket",
               types.ServerEventType.CRITICAL_ERROR,
               time.now(),
               false,
               path,
               mthd,
           )
           print_server_event_information(writeResponseToSocketFail)
           log_server_event(writeResponseToSocketFail)

           fmt.println("Error writing to socket:", write_err)
           return
       }

       fmt.println("Response sent successfully")
   }

   fmt.println("Connection handler stopping due to server shutdown")
}

//Looks over all the possible ports that OstrichDB uses. If the first is free, use it, if not use the next available port.
check_if_port_is_free :: proc(ports: []int) -> int {
   buf := new([8]byte)
   defer free(buf)

   for potentialPort in ports {
       portAsStr := strconv.itoa(buf[:], potentialPort)
       termCommand := fmt.tprintf("lsof -i :%s > /dev/null 2>&1", portAsStr)
       cString := strings.clone_to_cstring(termCommand)
       defer delete(cString)

       result := libc.system(cString)
       portFree := result != 0
       if portFree {
           return potentialPort
       }
   }

   return 0
}


@(cold) //TODO: Not sure if this should be cold or not
HANDLE_SERVER_KILL_SWITCH :: proc() {
    using lib
    using fmt
    using strings


	for isRunning {
		input := get_input(false)
		if input == "kill" || input == "exit" {
			// println("Stopping OstrichDB server...")
			isRunning = false
			//ping the server to essentially refresh it to ensure it stops thus breaking the server main loop
			for port in ServerPorts{
				portCString := clone_to_cstring(tprintf("nc -zv localhost %d", port))
				libc.system(portCString)
			}
			return
		} else do continue
	}
}


//TODO: rename and move this somewhere like common.odin or misc.odin
 give_description ::proc(method:string, constant:string) -> string{
   return clone(tprintf("Added %s dynamic %s route to router", method, constant),)
}