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


//Dont forget to delete() the return value in calling procedure
convert_record_to_int_array :: proc(rValue: string) -> ([dynamic]int, bool) {
	newIntArray := make([dynamic]int)
	parsedArray := parse_array(rValue)
	for item in parsedArray {
		value, ok := strconv.parse_int(item)
		append(&newIntArray, value)
	}

	return newIntArray, true
}

//Dont forget to delete() the return value in calling procedure
convert_record_to_float_array :: proc(rValue: string) -> ([dynamic]f64, bool) {
	newFloatArray := make([dynamic]f64)
	parsedArray := parse_array(rValue)
	for item in parsedArray {
		value, ok := strconv.parse_f64(item)
		append(&newFloatArray, value)
	}

	return newFloatArray, true
}

//Dont forget to delete() the return value in calling procedure
convert_record_to_bool_array :: proc(rValue: string) -> ([dynamic]bool, bool) {
	newBoolArray := make([dynamic]bool)
	parsedArray := parse_array(rValue)
	for item in parsedArray {
		itemLower := strings.to_lower(strings.trim_space(item))
		defer delete(itemLower)

		if itemLower == "true" || itemLower == "t" {
			append(&newBoolArray, true)
		} else if itemLower == "false" || itemLower == "f" {
			append(&newBoolArray, false)
		} else {
			fmt.printfln("Failed to parse bool array")
			return newBoolArray, false
		}
	}

	return newBoolArray, true
}

//Dont forget to delete() the return value in calling procedure
convert_record_to_string_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newStringArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for item in parsedArray {
		append(&newStringArray, item)
	}

	return newStringArray, true
}

//Dont forget to delete() the return value in calling procedure
convert_record_to_char_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newCharArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for item in parsedArray {
		append(&newCharArray, item)
	}

	return newCharArray, true
}

//Dont forget to delete() the return value in calling procedure
convert_record_to_date_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for item in parsedArray {
		dateValue, dateParseOk := parse_date(item)
		if dateParseOk {
			append(&newArray, date)
		} else {
			return newArray, false
		}
	}

	return newArray, true
}

//Dont forget to delete() the return value in calling procedure
convert_record_to_time_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newTimeArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for item in parsedArray {
		timeValue, timeParseOk := parse_time(item)
		if timeParseOk {
			append(&newTimeArray, timeValue)
		} else {
			return newTimeArray, false
		}
	}

	return newTimeArray, true
}

//Dont forget to delete() the return value in calling procedure
convert_record_to_datetime_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newDateTimeArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for item in parsedArray {
		datetimeValue, datetimeParseOk := parse_datetime(item)
		if datetimeParseOk {
			append(&newDateTimeArray, datetimeValue)
		} else {
			return newDateTimeArray, false
		}
	}

	return newDateTimeArray, true
}

convert_record_to_date :: proc(rValue: string) -> (string, bool) {
	dateValue, dateParseOk := parse_date(rValue)
	if dateParseOk == true {
		return dateValue, true
	}

	return "", false
}

convert_record_to_time :: proc(rValue: string) -> (string, bool) {
	timeValue, timeParseOk := parse_time(rValue)
	if timeParseOk == true {
		return timeValue, true
	}

	return "", false
}

convert_record_to_datetime :: proc(rValue: string) -> (string, bool) {
	datetimeValue, datetimeParseOk := parse_datetime(rValue)
	if datetimeParseOk == true {
		return datetimeValue, true
	}

	return "", false
}

convert_record_to_uuid :: proc(rValue: string) -> (string, bool) {
	uuidValue, uuidParseOk := parse_uuid(rValue)
	if uuidParseOk == true {
		return uuidValue, true
	}

	return "", false
}

//Dont forget to delete() the return value in calling procedure
convert_record_to_uuid_array :: proc(rValue: string) -> ([dynamic]string, bool) {
	newUUIDArray := make([dynamic]string)
	parsedArray := parse_array(rValue)
	for item in parsedArray {
		uuidValue, uuidParseOk := parse_uuid(item)
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
CONVERT_SINGLE_RECORD_VALUE_TO_NEW_TYPE :: proc(value, oldT, newT: string) -> (string, bool) {
	if len(value) == 0 {
		return "", true
	}
	oldVIsArray := strings.has_prefix(oldT, "[]")
	newVIsArray := strings.has_prefix(newT, "[]")


	//handle array conversion
	if oldVIsArray && newVIsArray { 	//if both are arrays
		values := parse_array(value) //parse the array
		newValues := make([dynamic]string) //create a new array to store the converted values
		defer delete(newValues)

		for val in values { 	//for each value in the array
			converted, ok := CONVERT_SINGLE_RECORD_VALUE(value, oldT, newT) //convert the value
			if !ok {
				return "", false
			}
			append(&newValues, converted) //append the converted value to the new array
		}
		return strings.join(newValues[:], ","), true
	}

	//handle single value conversion
	if !oldVIsArray && newVIsArray { 	//if the old value is not an array and the new value is
		converted, ok := CONVERT_SINGLE_RECORD_VALUE(value, oldT, newT) //convert the single value
		if !ok {
			return "", false
		}
		return converted, true
	}

	//handle array to single value conversion
	if oldVIsArray && !newVIsArray { 	//if the old value is an array and the new value is not
		values := parse_array(value) //parse the array
		if len(values) > 0 { 	//if there are values in the array
			firstValue := utils.strip_array_brackets(values[0])
			return CONVERT_SINGLE_RECORD_VALUE(firstValue, oldT, newT)
		}
		return "", true
	}

	//if both are single values
	return CONVERT_SINGLE_RECORD_VALUE(value, oldT, newT)
}


//Used to convert a single record value to a different value depending on the new type provided.
//e.g if converting an int: 123 to a string then it will return "123"
//filthy fucking code I am so sorry - Marshall
CONVERT_SINGLE_RECORD_VALUE :: proc(
	value: string,
	oldType: string,
	newType: string,
) -> (
	string,
	bool,
) {
	using const
	using types

	//if the types are the same, no conversion is needed
	if oldType == newType {
		return value, true
	}

	switch (newType) {
	case Token[.STRING]:
		//New type is STRING
		switch (oldType) {
		case Token[.INTEGER], Token[.FLOAT], Token[.BOOLEAN]:
			//Old type is INTEGER, FLOAT, or BOOLEAN
			value := utils.append_qoutations(value)
			return value, true
		case Token[.STRING_ARRAY]:
			newValue := utils.strip_array_brackets(value)
			if len(value) > 0 {
				return utils.append_qoutations(value), true
			}
			return "\"\"", true
		case:
			return "", false
		}
	case Token[.INTEGER]:
		//New type is INTEGER
		switch (oldType) {
		case Token[.STRING]:
			//Old type is STRING
			_, ok := strconv.parse_int(value, 10)
			if !ok {
				return "", false
			}
			return value, true
		case:
			return "", false
		}
	case Token[.FLOAT]:
		//New type is FLOAT
		switch (oldType) {
		case Token[.STRING]:
			//Old type is STRING
			_, ok := strconv.parse_f64(value)
			if !ok {
				return "", false
			}
			return value, true
		case:
			return "", false
		}
	case Token[.BOOLEAN]:
		//New type is BOOLEAN
		switch (oldType) {
		case Token[.STRING]:
			//Old type is STRING
			lowerStr := strings.to_lower(strings.trim_space(value))
			if lowerStr == "true" || lowerStr == "false" {
				return lowerStr, true
			}
			return "", false
		case:
			return "", false
		}
	//ARRAY CONVERSIONS
	case Token[.STRING_ARRAY]:
		// New type is STRING_ARRAY
		switch (oldType) {
		case Token[.STRING]:
			// Remove any existing quotes
			value := strings.trim_prefix(strings.trim_suffix(value, "\""), "\"")
			// Format as array with proper quotes
			return value, true
		case:
			return "", false
		}
	case Token[.INTEGER_ARRAY]:
		// New type is INTEGER_ARRAY
		switch (oldType) {
		case Token[.INTEGER]:
			// Remove any existing quotes
			value := strings.trim_prefix(strings.trim_suffix(value, "\""), "\"")
			// Format as array with proper quotes
			return value, true
		case:
			return "", false
		}
	case Token[.BOOLEAN_ARRAY]:
		// New type is BOOLEAN_ARRAY
		switch (oldType) {
		case Token[.BOOLEAN]:
			// Remove any existing quotes
			value := strings.trim_prefix(strings.trim_suffix(value, "\""), "\"")
			// Format as array with proper quotes
			return value, true
		case:
			return "", false
		}
	case Token[.FLOAT_ARRAY]:
		// New type is FLOAT_ARRAY
		switch (oldType) {
		case Token[.FLOAT]:
			// Remove any existing quotes
			value := strings.trim_prefix(strings.trim_suffix(value, "\""), "\"")
			// Format as array with proper quotes
			return value, true
		case:
			return "", false
		}
	case:
		return "", false
	}

	return "", false
}


//handles a records type and value change
HANDLE_RECORD_TYPE_CONVERSION :: proc(colPath, cn, rn, newType: string) -> bool {
	using data

	oldType, _ := GET_RECORD_TYPE(colPath, cn, rn)
	recordValue := GET_RECORD_VALUE(colPath, cn, oldType, rn)

	new_value, success := CONVERT_SINGLE_RECORD_VALUE_TO_NEW_TYPE(recordValue, oldType, newType)
	if !success {
		utils.log_err("Could not convert value to new type", #procedure)
		return false
	} else {

		typeChangeSucess := CHANGE_RECORD_TYPE(colPath, cn, rn, recordValue, newType)
		valueChangeSuccess := SET_RECORD_VALUE(colPath, cn, rn, new_value)
		if !typeChangeSucess || !valueChangeSuccess {
			utils.log_err("Could not change record type or value", #procedure)
			return false
		} else if typeChangeSucess && valueChangeSuccess {
			return true
		}
	}

	return false
}


//This proc looks for the passed in records array value and depending on the record type will format that value
//If the type is a []CHAR then remove the double qoutes and replace them with single qoutes
//if []DATE, []TIME, []DATETIME then remove the qoutes and replace them with nothing
MODIFY_ARRAY_VALUES :: proc(fn, cn, rn, rType: string) -> (string, bool) {
	using types
	// Get the current record value
	recordValue := GET_RECORD_VALUE(fn, cn, rType, rn)
	if recordValue == "" {
		return "", false
	}

	// Remove the outer brackets
	value := strings.trim_space(recordValue)
	if !strings.has_prefix(value, "[") || !strings.has_suffix(value, "]") {
		return "", false
	}
	value = value[1:len(value) - 1]

	// Split the array elements
	elements := strings.split(value, ",")
	defer delete(elements)

	// Create a new array to store modified values
	modifiedElements := make([dynamic]string)
	defer delete(modifiedElements)

	// Process each element based on type
	for element in elements {
		element := strings.trim_space(element)

		switch rType {
		case Token[.CHAR_ARRAY]:
			// Replace double quotes with single quotes
			if strings.has_prefix(element, "\"") && strings.has_suffix(element, "\"") {
				element = fmt.tprintf("'%s'", element[1:len(element) - 1])
			}
		case Token[.DATE_ARRAY], Token[.TIME_ARRAY], Token[.DATETIME_ARRAY]:
			// Remove quotes entirely
			if strings.has_prefix(element, "\"") && strings.has_suffix(element, "\"") {
				element = element[1:len(element) - 1]
			}
		}
		append(&modifiedElements, element)
	}

	// Join the modified elements back into an array string
	result := fmt.tprintf("[%s]", strings.join(modifiedElements[:], ", "))

	// Update the record with the modified value
	success := UPDATE_RECORD(fn, cn, rn, result)

	return result, success
}