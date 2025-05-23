package engine

import lib"../../library"
import "core:fmt"
import "core:os"
import "core:strings"

@(require_results)
make_new_query::proc(input:string) -> ^lib.Query{
    using lib
    using strings

    query:= new(Query)
    query.CommandToken = .INVALID
    query.LocationToken = make([dynamic]string, 0)
    query.ParameterToken = make(map[string]string)
    query.isChained = false
    query.rawInput = clone(input)

    return query
}

@(require_results) //Todo: Add optimation attribute for speed
parse_query ::proc(query: ^lib.Query) -> (^lib.Query, bool){
    using lib
    using strings

    success:= false

    //Todo: identifier and value tokens need to be sent back to the case theat the user provides them
    // as opposed to keeping them all capped like here
   	input := to_upper(query.rawInput)
    defer delete(input)

    //Break query into Tokens
	tokens := split(trim_space(input), " ")
	defer delete(tokens)

	//Determine if this query is chained
    if contains(query.rawInput, "&&"){
        query.isChained = true
    }

    if len(tokens) == 0{
        make_new_err(.INVALID_QUERY_LENGTH, get_caller_location())
        return query, success
    }

    // Convert first token to TokenType
	query.CommandToken = convert_input_string_to_token(tokens[0])
	state := QueryParserState.ExpectingCommandToken //state machine exclusively used for parameter token shit
	currentParameterToken := "" //stores the current modifier such as TO
	collectingString := false
	stringValue := ""
	defer delete(stringValue)

	//iterate over remaining CLP tokens and set/append them to the cmd
	for i := 1; i < len(tokens); i += 1 {
		token := tokens[i]
		if collectingString {
			if stringValue != "" {
				stringValue = concatenate([]string{stringValue, " ", token})
			} else {
				stringValue = token
			}
			continue
		}
		switch state {
		    case .ExpectingCommandToken:
				// Expecting command token
				if contains(token, ".") {
					tokensSeperatedByDot := split(trim_space(token), ".")
					defer delete(tokensSeperatedByDot)
					for tok in tokensSeperatedByDot {
						append(&query.LocationToken, tok)
					}
				} else {
					append(&query.LocationToken, token)
				}
				state = .ExpectingParameterToken
				break
		    case .ExpectingParameterToken:
				// Expecting object or modifier
			    if check_if_param_token_is_valid(token) {
				    currentParameterToken = token
				    state = .ExpectingValue
			    } else {
				    if contains(token, ".") {
					    tokensSeperatedByDot := split(trim_space(token), ".")
					    defer delete(tokensSeperatedByDot)
					    for tok in tokensSeperatedByDot {
						    append(&query.LocationToken, tok)
					    }
				    } else {
					    append(&query.LocationToken, token)
				    }
			    }
		    case .ExpectingValue:
				stringValue = token
				collectingString = true
		}
	}

	// If we collected a string value, store it
	if collectingString && stringValue != "" {
		query.ParameterToken[currentParameterToken] = stringValue

		// If the current parameter token is OF_TYPE and the CommandToken is NEW
		// Check if the string value contains the WITH token to handle record values
		if currentParameterToken == TokenStrings[.OF_TYPE] && query.CommandToken == .NEW {
			// Split the string to check for WITH token
			parts := split(stringValue, " ")
			defer delete(parts)
			if len(parts) >= 2 && strings.to_upper(parts[1]) == TokenStrings[.WITH] {

				// Store the type in the OF_TYPE map value slot
				query.ParameterToken[currentParameterToken] = parts[0]

				// Store everything after the WITH token in the WITH map value slot
				if len(parts) > 2 {
					withValue := strings.join(parts[2:], " ")
					query.ParameterToken[TokenStrings[.WITH]] = withValue
				} else {
					// Handle case where WITH is the last token with no value
					query.ParameterToken[TokenStrings[.WITH]] = ""
				}
			}
		}
		success = true
	}

	return query, success
}

//TODO: unsure if this proc should be passed a string or a ^lib.Query - Marshall
@(require_results)
parse_chained_command :: proc(input: string) -> ^lib.Query {
    using strings

    query:= make_new_query(input)
    parts := split(input, "&&")
    defer delete(parts)

    if len(parts) > 0 {
        commandToken := trim_space(parts[0])
        defer delete(commandToken)

        firstTokens := split(trim_space(commandToken), " ")
        defer delete(firstTokens)

        if len(firstTokens) > 0 {
            query.CommandToken = convert_input_string_to_token(firstTokens[0])
        }
    }

    return query
}


//checks if a token is a valid parameter token
@(require_results)
check_if_param_token_is_valid :: proc(token: string) -> bool {
	using lib

	validParamTokens := []string{TokenStrings[.WITH],TokenStrings[.OF_TYPE], TokenStrings[.TO]}
	for paramToken in validParamTokens {
		if strings.to_upper(token) == paramToken {
			return true
		}
	}
	return false
}

//take the string representation of a token and returns the token itself
convert_input_string_to_token :: proc(strValue: string) -> lib.QueryToken {
	using lib

	strValueUpper := strings.to_upper(strValue)
	for tokenAsString, index in QueryTokenString {
		if strValueUpper == tokenAsString {
			return index
		}
	}
	return .INVALID
}

