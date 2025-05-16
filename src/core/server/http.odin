package server
import lib "../../library"
import "core:strings"
import "core:fmt"


parse_http_request :: proc(rawData:[]byte) -> (method: lib.HttpMethod, path: string, headers: map[string]string){
    using lib

    requestDataString:= string(rawData)
    lines:= strings.split(requestDataString, "\r\n")

    if len(lines) < 1 {
        return nil, "Http request empty", nil
    }

    requestParts:= strings.fields(lines[0])

   	if len(requestParts) != 3 {
		fmt.println("Error: Request line does not have exactly 3 parts")
		return nil, "", nil
	}

	methodStringPart := strings.trim_space(requestParts[0])


	for httpMethod , index in HttpMethodString{
	    if methodStringPart == httpMethod{
		   method = index //Todo: not sure if this is right


			break

	   }
	}
	path = strings.trim_space(requestParts[1])


}