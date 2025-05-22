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

// CorsOptions defines the configuration for CORS
CorsOptions :: struct {
    allow_origins: []string,           // List of allowed origins, use ["*"] for all
    allow_methods: []lib.HttpMethod,   // List of allowed HTTP methods
    allow_headers: []string,           // List of allowed headers
    expose_headers: []string,          // List of headers exposed to the browser
    allow_credentials: bool,           // Whether to allow credentials (cookies, etc.)
    max_age: int,                      // How long preflight requests can be cached (in seconds)
}

// Default CORS options that allow specific origins and common methods
default_cors_options :: proc() -> CorsOptions {
    using lib
    
    // Generate allowed origins based on ServerPorts
    allowed_origins := make([dynamic]string)
    
    // Add http and https protocols
    append(&allowed_origins, "http://*")
    append(&allowed_origins, "https://*")
    
    // Add origins from ServerPorts in constants.odin
    for port in ServerPorts {
        append(&allowed_origins, fmt.tprintf("http://localhost:%d", port))
        append(&allowed_origins, fmt.tprintf("https://localhost:%d", port))
    }
    
    return CorsOptions{
        allow_origins = allowed_origins[:],
        allow_methods = []HttpMethod{.GET, .POST, .PUT, .DELETE, .HEAD, .OPTIONS},
        allow_headers = []string{"Content-Type", "Authorization"},
        expose_headers = []string{},
        allow_credentials = false,
        max_age = 86400, // 24 hours
    }
}


// Apply CORS headers to response
apply_cors_headers :: proc(headers: ^map[string]string, request_headers: map[string]string, method: lib.HttpMethod) {
    using lib
    
    cors_options := default_cors_options()
    
    // Get the Origin header from the request
    origin, has_origin := request_headers["Origin"]
    
    if has_origin {
        // Check if the origin is allowed
        is_allowed := false
        for allowed_origin in cors_options.allow_origins {
            if allowed_origin == "*" || allowed_origin == origin {
                is_allowed = true
                break
            }
            
            // Check for wildcard subdomains (e.g., http://* matches http://example.com)
            if strings.has_suffix(allowed_origin, "://*") {
                protocol := strings.split(allowed_origin, "://*")[0]
                if strings.has_prefix(origin, fmt.tprintf("%s://", protocol)) {
                    is_allowed = true
                    break
                }
            }
        }
        
        if is_allowed {
            headers["Access-Control-Allow-Origin"] = origin
            
            if cors_options.allow_credentials {
                headers["Access-Control-Allow-Credentials"] = "true"
            }
            
            if method == .OPTIONS {
                // Convert HttpMethod enum to string for the Allow-Methods header
                methods_str := strings.join(transmute([]string)cors_options.allow_methods[:], ", ")
                headers["Access-Control-Allow-Methods"] = methods_str
                
                headers["Access-Control-Allow-Headers"] = strings.join(cors_options.allow_headers, ", ")
                headers["Access-Control-Max-Age"] = fmt.tprintf("%d", cors_options.max_age)
            }
            
            if len(cors_options.expose_headers) > 0 {
                headers["Access-Control-Expose-Headers"] = strings.join(cors_options.expose_headers, ", ")
            }
        }
    }
}
// Handle OPTIONS preflight requests
handle_options_request :: proc(method: lib.HttpMethod, path: string, headers: map[string]string, args: []string = {""}) -> (^lib.HttpStatus, string) {
    using lib

    // Create response headers with CORS headers
    response_headers := make(map[string]string)
    // defer delete(response_headers)

    // Apply default CORS options
    apply_cors_headers(&response_headers, headers, method)

    // Return 204 No Content for OPTIONS requests
    return make_new_http_status(.NO_CONTENT, HttpStatusText[.NO_CONTENT]), ""
}