package data

import lib "../../../library"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:unicode/utf8"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains logic for how OstrichLite handles'complex' data types.
            e.g dates, times, arrays, etc...
*********************************************************/


//split the passed in "array" which is actually a string from whatever input system is in place(e.g the in the OstrichDB CLI the usesr input would be passed)
@(require_results)
parse_array :: proc(arrayAsString:string) -> []string {
    result := strings.split(arrayAsString, ",")
	return result
}

//verifies that the members of the passed in array are valid based on the type of array they are in
@(require_results)
verify_array_values :: proc(record: ^lib.Record) -> bool {
	using lib
	using strconv

	verified := false
	//retrieve the record type
	parsedArray := parse_array(record.value)

	#partial switch (record.type) {
	case .INTEGER_ARRAY:
		for element in parsedArray {
			_, parseSuccess := parse_int(element)
			verified = parseSuccess
		}
		return verified
	case .FLOAT_ARRAY:
		for element in parsedArray {
			_, parseSuccess := parse_f64(element)
			verified = parseSuccess
		}
		return verified
	case .BOOLEAN_ARRAY:
		for element in parsedArray {
			_, parseSuccess := parse_bool(element)
			verified = parseSuccess
		}
		return verified
	case .DATE_ARRAY:
		for element in parsedArray {
			_, parseSuccess := parse_date(element)
			verified = parseSuccess
		}
		return verified
	case .TIME_ARRAY:
		for element in parsedArray {
			_, parseSuccess := parse_time(element)
			verified = parseSuccess
		}
		return verified
	case .DATETIME_ARRAY:
		for element in parsedArray {
			_, parseSuccess := parse_datetime(element)
			verified = parseSuccess
		}
		return verified
	case .STRING_ARRAY, .CHAR_ARRAY:
		verified = true
		return verified
	case .UUID_ARRAY:
		for element in parsedArray {
			_, parseSuccess := parse_uuid(element)
			verified = parseSuccess
		}
		return verified
	}

	return verified
}


//validates the passed in date and returns it
//remember to delete return value in from calling procedure
@(require_results)
parse_date :: proc(date: string) -> (string, bool) {
    using lib
    using fmt
    using strings
    using strconv

	success:= false
	dateString := ""

	parts, splitError := split(date, "-")
	defer delete(parts)
	if splitError != .None{
	    return "", success
	}

	//check length requirments
	if len(parts[0]) != 4 || len(parts[1]) != 2 || len(parts[2]) != 2 {
		return dateString, success
	}

	year, yearParsedOk := parse_int(parts[0])
	month, monthParsedOk := parse_int(parts[1])
	day, dayParsedOk := parse_int(parts[2])

	if !yearParsedOk || !monthParsedOk || !dayParsedOk {
		return dateString, success
	}

	//validate month range
	if month < 1 || month > 12 {
		return dateString, success
	}

	//Calculate days in month
	daysInMonth := 31
	switch month {
	    case 4, 6, 9, 11:
			daysInMonth = 30
			break
		case 2:
		    // Leap year calculation
		    isLeapYear := (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
		    daysInMonth = isLeapYear ? 29 : 28
		    break
	}

	// Validate day range
	if day < 1 || day > daysInMonth {
		return dateString, success
	}

	success = true

	// Format with leading zeros
	monthString := tprintf("%02d", month)
	dayString := tprintf("%02d", day)
	yearString := tprintf("%04d", year)
	dateString = tprintf("%s-%s-%s", yearString, monthString, dayString)

	return clone(dateString), success
}

//validates the passed in time and returns it
//remember to delete return value in from calling procedure
@(require_results)
parse_time :: proc(time: string) -> (string, bool) {
    using lib
    using fmt
    using strings
    using strconv

    success:=false
	timeString := ""

	parts, splitError := split(time, ":")
	defer delete(parts)
	if splitError != .None{
	    return timeString, success
	}

	if len(parts[0]) != 2 || len(parts[1]) != 2 || len(parts[2]) != 2 {
		return timeString, success
	}

	// Convert strings to integers for validation
	hour, hourParsedOk := parse_int(parts[0])
	minute, minuteParsedOk := parse_int(parts[1])
	second, secondParsedOk := parse_int(parts[2])

	if !hourParsedOk || !minuteParsedOk || !secondParsedOk {
		return timeString, success
	}

	// Validate ranges
	if hour < 0 || hour > 23 {
		return timeString, success
	}
	if minute < 0 || minute > 59 {
		return timeString, success
	}
	if second < 0 || second > 59 {
		return timeString, success
	}

	success = true
	// Format with leading zeros
	timeString = tprintf("%02d:%02d:%02d", hour, minute, second)

	return clone(timeString), success
}

//validates the passed in datetime and returns it
//Example datetime: 2024-03-14T09:30:00
//remember to delete return value in from calling procedure
@(require_results)
parse_datetime :: proc(dateTime: string) -> (string, bool) {
    using lib
    using fmt
    using strings
    using strconv

    success:= false
    dateTimeString := ""

    dateTimeArr, splitError := split(dateTime, "T")
    defer delete(dateTimeArr)
    if splitError != .None{
        return dateTimeString, success
    }

	dateString, dateParseSuccess := parse_date(dateTimeArr[0])
	if !dateParseSuccess {
		return dateTimeString, success
	}

	timeString, timeParseSuccess := parse_time(dateTimeArr[1])
	if !timeParseSuccess{
		return dateTimeString, success
	}

	success = true
	dateTimeString = tprintf("%sT%s", dateString, timeString)

	return clone(dateTimeString), success
}


//parses the passed in string ensuring proper format and length
//Must be in the format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
//Only allows 0-9 and a-f
//remember to delete return value in from calling procedure
@(require_results)
parse_uuid :: proc(uuid: string) -> (string, bool) {
    using lib
    using fmt
    using strings
    using strconv

    success:=false
	isValidChar := false
	uuidString := ""

	possibleChars: []string = {
		"0",
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
	}

	parts, splitSuccess := split(uuid, "-")
	defer delete(parts)
	if splitSuccess != .None{
        return uuidString, success
	}


	if len(parts[0]) != 8 ||
	   len(parts[1]) != 4 ||
	   len(parts[2]) != 4 ||
	   len(parts[3]) != 4 ||
	   len(parts[4]) != 12 {
		return uuidString, success
	}

	// Validate each section of the UUID
	for section in parts {
		for value in section {
			// Convert the rune to a lowercase string
			runeArr := make([]rune, 1)
			defer delete(runeArr)

			runeArr[0] = value
			charLower := to_lower(utf8.runes_to_string(runeArr)) //convert the Odin rune to a string so it can be returned
			isValidChar = false

			// Check if the character is in the allowed set
			for char in possibleChars {
				if charLower == char {
					isValidChar = true
					break
				}
			}

			if !isValidChar {
				return uuidString, success
			}
		}
	}

	uuidString = fmt.tprintf(
		"%s-%s-%s-%s-%s",
		parts[0],
		parts[1],
		parts[2],
		parts[3],
		parts[4],
	)
	success = true
	uuidString = to_lower(uuidString)

	return clone(uuidString), success
}