package server

import lib "../../library"
import "core:fmt"
import "core:strings"

/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains logic for handling Cross-Origin Resource Sharing (CORS)
            for the OstrichLite server.
*********************************************************/


// Default CORS options that allow specific origins and common methods
make_default_cors_options :: proc() -> ^lib.CorsOptions {
    using lib
    using fmt

    defaultCorsOptions := new(lib.CorsOptions)

    allowedOrigins:= make([dynamic]string)
    append(&allowedOrigins, "http://")
    append(&allowedOrigins, "https://")

    for port in ServerPorts {
        append(&allowedOrigins, fmt.tprintf("http://localhost:%d", port))
        append(&allowedOrigins, fmt.tprintf("https://localhost:%d", port))
    }

    defaultCorsOptions.allowOrigins = allowedOrigins[:]
    defaultCorsOptions.allowMethods = []HttpMethod{.GET, .POST, .PUT, .DELETE, .HEAD, .OPTIONS}
    defaultCorsOptions.allowHeaders = []string{"Content-Type", "Authorization"}
    defaultCorsOptions.exposeHeaders = []string{}
    defaultCorsOptions.allowCredentials = false
    defaultCorsOptions.maxAge = 86400 // 24 hours

    delete(allowedOrigins)

    return defaultCorsOptions

}



// Apply CORS headers to response
apply_cors_headers :: proc(headers: ^map[string]string, requestHeaders: map[string]string, method: lib.HttpMethod) {
    using lib

    defer free_all() //Tbh not sure id this is freeing the headers allocation or not...

    corsOptions := make_default_cors_options()
    defer free(corsOptions)

    // Get the Origin header from the request
    origin, hasOrigin := requestHeaders["Origin"]

    if hasOrigin {
        // Check if the origin is allowed
        isAllowed := false
        for allowedOrigin in corsOptions.allowOrigins {
            if allowedOrigin == "*" || allowedOrigin == origin {
                isAllowed = true
                break
            }

            // Check for wildcard subdomains (e.g., http://* matches http://example.com)
            if strings.has_suffix(allowedOrigin, "://*") {
                protocol := strings.split(allowedOrigin, "://*")[0]
                defer delete(protocol)
                if strings.has_prefix(origin, fmt.tprintf("%s://", protocol)) {
                    isAllowed = true
                    break
                }
            }
        }

        if isAllowed {
            headers["Access-Control-Allow-Origin"] = origin

            if corsOptions.allowCredentials {
                headers["Access-Control-Allow-Credentials"] = "true"
            }

            if method == .OPTIONS {
                // Convert HttpMethod enum to string for the Allow-Methods header
                allowedMethodsAsString := strings.join(transmute([]string)corsOptions.allowMethods[:], ", ")
                defer delete(allowedMethodsAsString)
                headers["Access-Control-Allow-Methods"] = allowedMethodsAsString

                headers["Access-Control-Allow-Headers"] = strings.join(corsOptions.allowHeaders, ", ")
                headers["Access-Control-Max-Age"] = fmt.tprintf("%d", corsOptions.maxAge)
            }

            if len(corsOptions.exposeHeaders) > 0 {
                headers["Access-Control-Expose-Headers"] = strings.join(corsOptions.exposeHeaders, ", ")
            }
        }
    }
}
// Handle OPTIONS preflight requests
handle_options_request :: proc(method: lib.HttpMethod, path: string, headers: map[string]string, args: []string = {""}) -> (^lib.HttpStatus, string) {
    using lib

    // Create response headers with CORS headers
    response_headers := make(map[string]string)
    defer delete(response_headers)

    // Apply default CORS options
    apply_cors_headers(&response_headers, headers, method)

    // Return 204 No Content for OPTIONS requests
    return make_new_http_status(.NO_CONTENT, HttpStatusText[.NO_CONTENT]), ""
}