package data

import lib "../../../library"
import "core:fmt"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains logic for handling the conversion of record data
            types within OstrichLite
*********************************************************/

//The following conversion procs are used to convert the passed in record value to the correct data type
convert_record_to_int :: proc(rValue: string) -> (int, bool) {
	value, intParseOk := strconv.parse_int(rValue)
	if intParseOk {
		return value, true
	} else {
		return -1, false
	}
}

covert_record_to_float :: proc(rValue: string) -> (f64, bool) {
	value, floatParseOk := strconv.parse_f64(rValue)
	if floatParseOk {
		return value, true
	} else {
		return -1.0, false
	}
}

convert_record_to_bool :: proc(rValue: string) -> (bool, bool) {
	valueLower := strings.to_lower(strings.trim_space(rValue))
	defer delete(valueLower)

	if valueLower == "true" || valueLower == "t" {  //This remnant from the OstrichCLI allowed a user to set a record value to t or f and it would be assigned true or false
		return true, true
	} else if valueLower == "false" || valueLower == "f" {
		return false, true
	} else {
		//no need to do anything other than return here. Once false is returned error handling system will do its thing
		return false, false
	}
}

//converts the passed in record value to a valid date format as a string and returns it
convert_record_to_date :: proc(rValue: string) -> (string, bool) {
	dateValue, dateParseOk := parse_date(rValue)
	if dateParseOk == true {
		return dateValue, true
	}

	return "", false
}

//converts the passed in record value to a valid time format as a string and returns it
convert_record_to_time :: proc(rValue: string) -> (string, bool) {
	timeValue, timeParseOk := parse_time(rValue)
	if timeParseOk == true {
		return timeValue, true
	}

	return "", false
}

//converts the passed in record value to a valid datetime format as a string and returns it
//example: 2023-08-20T12:34:56
convert_record_to_datetime :: proc(rValue: string) -> (string, bool) {
	datetimeValue, datetimeParseOk := parse_datetime(rValue)
	if datetimeParseOk == true {
		return datetimeValue, true
	}

	return "", false
}

//converts the passed in record value to a valid uuid format as a string and returns it
convert_record_to_uuid :: proc(rValue: string) -> (string, bool) {
	uuidValue, uuidParseOk := parse_uuid(rValue)
	if uuidParseOk == true {
		return uuidValue, true
	}

	return "", false
}


//converts the passed in record value to a valid int array format and returns it
//Dont forget to delete() the return value in calling procedure
convert_record_to_int_array :: proc(rValue: string) -> ([dynamic]int, bool) {
	newIntArray := make([dynamic]int)
	parsedArray := parse_array(rValue)
	for element in parsedArray {
		value, ok := strconv.parse_int(element)
		append(&newIntArray, value)
	}

	return newIntArray, true
}

//converts the passed in record value to a valid float array format and returns it
//Dont forget to delete() the return value in calling procedure
convert_record_to_float_array :: proc(rValue: string) -> ([dynamic]f64, bool) {
	newFloatArray := make([dynamic]f64)
	parsedArray := parse_array(rValue)
	for element in parsedArray {
		value, ok := strconv.parse_f64(element)
		append(&newFloatArray, value)
	}

	return newFloatArray, true
}

//converts the passed in record value to a valid bool array format and returns it
//Dont forget to delete() the return value in calling procedure
convert_record_to_bool_array :: proc(rValue: string) -> ([dynamic]bool, bool) {
	newBoolArray := make([dynamic]bool)
	parsedArray := parse_array(rValue)
	for element in parsedArray {
		elementLower := strings.to_lower(strings.trim_space(element))
		defer delete(elementLower)

		if elementLower == "true" || elementLower == "t" {
			append(&newBoolArray, true)
		} else if elementLower == "false" || elementLower == "f" {
			append(&newBoolArray, false)
		} else {
			fmt.printfln("Failed to parse bool array")
			return newBoolArray, false
		}
	}

	return newBoolArray, true
}

//converts the passed in record value to a valid string array format and returns it
//Dont forget to delete() the return value in calling procedure
convert_record_to_string_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newStringArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for element in parsedArray {
		append(&newStringArray, element)
	}

	return newStringArray, true
}

//converts the passed in record value to a valid char array format and returns it
//Dont forget to delete() the return value in calling procedure
convert_record_to_char_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newCharArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for element in parsedArray {
		append(&newCharArray, element)
	}

	return newCharArray, true
}

//converts the passed in record value to a valid date array format and returns it
//Dont forget to delete() the return value in calling procedure
convert_record_to_date_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newDateArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for element in parsedArray {
		dateValue, dateParseOk := parse_date(element)
		if dateParseOk {
			append(&newDateArray, dateValue)
		} else {
			return newDateArray, false
		}
	}

	return newDateArray, true
}

//converts the passed in record value to a valid time array format and returns it
//Dont forget to delete() the return value in calling procedure
convert_record_to_time_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newTimeArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for element in parsedArray {
		timeValue, timeParseOk := parse_time(element)
		if timeParseOk {
			append(&newTimeArray, timeValue)
		} else {
			return newTimeArray, false
		}
	}

	return newTimeArray, true
}

//converts the passed in record value to a valid datetime array format and returns it
//Dont forget to delete() the return value in calling procedure
convert_record_to_datetime_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newDateTimeArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for element in parsedArray {
		datetimeValue, datetimeParseOk := parse_datetime(element)
		if datetimeParseOk {
			append(&newDateTimeArray, datetimeValue)
		} else {
			return newDateTimeArray, false
		}
	}

	return newDateTimeArray, true
}

//converts the passed in record value to a valid uuid array format and returns it
//Dont forget to delete() the return value in calling procedure
convert_record_to_uuid_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newUUIDArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for element in parsedArray {
		uuidValue, uuidParseOk := parse_uuid(element)
		if uuidParseOk {
			append(&newUUIDArray, uuidValue)
		} else {
			return newUUIDArray, false
		}
	}

	return newUUIDArray, true
}


//Handles the conversion of a record value from the old type to a new type
//this could also go into the records.odin file but will leave it here for now
//Dont forget to delete() the return value in calling procedure
convert_record_with_type_change :: proc(value, oldT, newT: string) -> (string, bool) {
    using strings

    succes:= false

    if len(value) == 0 {
		return "", succes
	}

	oldValueIsArray := strings.has_prefix(oldT, "[]")
	newValueIsArray := strings.has_prefix(newT, "[]")

	//handle array conversion
	if oldValueIsArray && newValueIsArray {
		parsedArray := parse_array(value)
		newArray := make([dynamic]string)
		defer delete(newArray)

		for element in parsedArray {
			convertedValue, conversionSuccess := convert_primitive_value(element, oldT, newT) //convert the value
			if !conversionSuccess {
				return "", succes
			}else{
			    append(&newArray, convertedValue) //append the converted value to the new array
				succes = true
			}
		}

		return strings.join(newArray[:], ","), succes
	}

	//handle single value conversion
	if !oldValueIsArray && newValueIsArray { 	//if the old value is not an array and the new value is
		convertedValue, coversionSuccess := convert_primitive_value(value, oldT, newT) //convert the single value
		if !coversionSuccess {
			return "", succes
		}else{
		    succes = true
		}

		return convertedValue, true
	}

	//handle array to single value conversion
	if oldValueIsArray && !newValueIsArray { 	//if the old value is an array and the new value is not
		parsedArray := parse_array(value) //parse the array
		if len(parsedArray) > 0 { 	//if there are parsedArray in the array
		    firstValue := lib.strip_array_brackets(parsedArray[0])
			convertedValue, conversionSuccess:= convert_primitive_value(firstValue, oldT, newT)
			if !conversionSuccess{
			    return "", succes
			}else{
			    succes = true
			}
			return convertedValue, succes
		}
	}

	//if the old and new value are both single values
	convertedValue, conversionSuccess:=convert_primitive_value(value, oldT, newT)
	if !conversionSuccess{
	    return "", false
	}else {
	    succes = true
	}

	return convertedValue, succes
}


//Used to convert a single record value to a different value depending on the new type provided.
//e.g if converting an int: 123 to a string then it will return "123"
//Dont forget to free the memory in the calling procedure
convert_primitive_value :: proc(value: string, oldType: string, newType: string) -> (string, bool) {
	using lib
	using fmt
	using strings
	using strconv

	//if the types are the same, no conversion is needed
	if oldType == newType {
		return value, true
	}

	switch (newType) {
	case RecordDataTypesStrings[.STRING]:
		//New type is STRING
		switch (oldType) {
		case RecordDataTypesStrings[.INTEGER], RecordDataTypesStrings[.FLOAT], RecordDataTypesStrings[.BOOLEAN]:
			//Old type is INTEGER, FLOAT, or BOOLEAN
			quotedValue := append_qoutations(value)
			return quotedValue, true
		case RecordDataTypesStrings[.STRING_ARRAY]:
			newValue := strip_array_brackets(value)
			if len(newValue) > 0 {
				quotedValue := append_qoutations(newValue)
				return quotedValue, true
			}
			return "\"\"", true
		case:
			return "", false
		}
	case RecordDataTypesStrings[.INTEGER]:
		//New type is INTEGER
		switch (oldType) {
		case RecordDataTypesStrings[.STRING]:
			//Old type is STRING
			_, intParseOK := parse_int(value, 10)
			if !intParseOK {
				return "", false
			}
			return value, true
		case:
			return "", false
		}
	case RecordDataTypesStrings[.FLOAT]:
		//New type is FLOAT
		switch (oldType) {
		case RecordDataTypesStrings[.STRING]:
			//Old type is STRING
			_, floatParseOk := parse_f64(value)
			if !floatParseOk {
				return "", false
			}
			return value, true
		case:
			return "", false
		}
	case RecordDataTypesStrings[.BOOLEAN]:
		//New type is BOOLEAN
		switch (oldType) {
		case RecordDataTypesStrings[.STRING]:
			//Old type is STRING
			lowerStr := strings.to_lower(strings.trim_space(value))
			defer delete(lowerStr)
			if lowerStr == "true" || lowerStr == "false" {
				return lowerStr, true
			}
			return "", false
		case:
			return "", false
		}
	//ARRAY CONVERSIONS
	case RecordDataTypesStrings[.STRING_ARRAY]:
		// New type is STRING_ARRAY
		switch (oldType) {
		case RecordDataTypesStrings[.STRING]:
			// Remove any existing quotes
			unquotedValue := strings.trim_prefix(strings.trim_suffix(value, "\""), "\"")
			defer delete(unquotedValue)
			// Format as array with proper quotes
			return fmt.tprintf("[\"%s\"]", unquotedValue), true
		case:
			return "", false
		}
	case RecordDataTypesStrings[.INTEGER_ARRAY]:
		// New type is INTEGER_ARRAY
		switch (oldType) {
		case RecordDataTypesStrings[.INTEGER]:
			// Format as array
			return tprintf("[%s]", value), true
		case:
			return "", false
		}
	case RecordDataTypesStrings[.BOOLEAN_ARRAY]:
		// New type is BOOLEAN_ARRAY
		switch (oldType) {
		case RecordDataTypesStrings[.BOOLEAN]:
			// Format as array
			return tprintf("[%s]", value), true
		case:
			return "", false
		}
	case RecordDataTypesStrings[.FLOAT_ARRAY]:
		// New type is FLOAT_ARRAY
		switch (oldType) {
		case RecordDataTypesStrings[.FLOAT]:
			// Format as array
			return tprintf("[%s]", value), true
		case:
			return "", false
		}
	}

	return "", false
}


//The only proc in this file that actually physically causes a change in a collection
//handles a records type and value change
convert_record_type_then_update :: proc(collection: ^lib.Collection,cluster:^lib.Cluster, record:^lib.Record, newType: string) -> bool {
	using lib

	success:= false
	oldType, getRecordTypeSuccess := get_record_type(collection, cluster, record)
	if !getRecordTypeSuccess{
	    return success
	}

	recordValue, getRecordValueSuccess := get_record_value(collection, cluster, record)
	if !getRecordValueSuccess{
	    return success
	}


	newRecordValue, conversionSuccess := convert_record_with_type_change(recordValue, oldType, newType)
	if !conversionSuccess {
		return success
	} else {
		typeChangeSucess := update_record_data_type(collection, cluster, record , newType)
		valueChangeSuccess := update_record_value(collection, cluster, record, newRecordValue) //might need to use set_record_value() but that would requir refactor of that proc to accept new arg
		if !typeChangeSucess || !valueChangeSuccess {
			return success
		} else if typeChangeSucess && valueChangeSuccess {
		    success =  true
		}
	}

	return success
}


//This proc formats array values based on their type:
//- For []CHAR arrays: Replaces double quotes with single quotes
//- For []DATE, []TIME, []DATETIME arrays: Removes quotes entirely
//Dont forget to free the memory in the calling procedure
format_array_values_by_type :: proc(collection: ^lib.Collection, cluster: ^lib.Cluster, record: ^lib.Record) -> (string, bool) {
	using lib
	using strings

	success:= false

	recordValue, getRecordSuccess := get_record_value(collection, cluster, record)
	if !getRecordSuccess || recordValue == ""{
		return "", success
	}

	// Remove the outer brackets
	value := trim_space(recordValue)
	defer delete(value)

	if !has_prefix(value, "[") || !has_suffix(value, "]") {
		return "", false
	}

	value = value[1:len(value) - 1]

	// Split the array elements
	elements := split(value, ",")
	defer delete(elements)

	// Create a new array to store modified values
	modifiedElements := make([dynamic]string)
	defer delete(modifiedElements)

	// Process each element based on type
	for element in elements {
		element := trim_space(element)
		defer delete(element)

		#partial switch record.type {
		case .CHAR_ARRAY:
			// Replace double quotes with single quotes
			if has_prefix(element, "\"") && has_suffix(element, "\"") {
				element = fmt.tprintf("'%s'", element[1:len(element) - 1])
			}
		case .DATE_ARRAY, .TIME_ARRAY, .DATETIME_ARRAY:
			// Remove quotes entirely
			if has_prefix(element, "\"") && has_suffix(element, "\"") {
				element = element[1:len(element) - 1]
			}
		}
		append(&modifiedElements, element)
	}

	// Join the modified elements back into an array string
	result := fmt.tprintf("[%s]", strings.join(modifiedElements[:], ", "))

	// Update the record with the modified value
	updateRecordSuccess := update_record_value(collection, cluster, record, result)
	if !updateRecordSuccess{
	    return "", success
	}else{
	    success  = true
	}

	return result, success
}