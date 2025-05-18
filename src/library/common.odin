package library

import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file contains all the logic for interacting with
            collections within the OstrichLite engine.
*********************************************************/

// Helper proc that reads an entire file and returns the content as bytes along with a success boolean
read_file :: proc(filepath: string, callingProcedure: SourceCodeLocation) -> ([]byte, bool) {
	data, readSuccess := os.read_entire_file(filepath)
	if !readSuccess {
	errorLocation := get_caller_location()
		error := new_err(
			.CANNOT_READ_FILE,
			ErrorMessage[.CANNOT_READ_FILE],
			errorLocation
		)
		fmt.printfln("Internal Error reading file %s passed from calling procedure%s", filepath, callingProcedure.procedure)
		log_err(fmt.tprintf("Internal Error reading file %s", filepath), errorLocation)
		return nil, false
	}
	return data, true
}



// Helper proc that writes data to a file and returns a success boolean
write_to_file :: proc(filepath: string, data: []byte, callingProcedure: SourceCodeLocation) -> bool {
	writeSuccess := os.write_entire_file(filepath, data)
	if !writeSuccess {
	errorLocation:= get_caller_location()
		error := new_err(
			.CANNOT_WRITE_TO_FILE,
			ErrorMessage[.CANNOT_WRITE_TO_FILE],
			errorLocation
		)
		throw_err(error)
		fmt.printfln("Internal Error writing to file %s passed from calling procedure%s", filepath, callingProcedure.procedure)
		log_err(fmt.tprintf("Error writing to file: %s: ", filepath), errorLocation)
		return false
	}
	return true
}

// Helper proc that opens a file with specified flags and returns file handle and success boolean
open_file :: proc(
	filepath: string,
	flags: int,
	mode: int,
) -> (
	os.Handle,
	bool,
) {
	handle, openSuccess := os.open(filepath, flags, mode)
	if openSuccess != 0 {
		errorLocation := get_caller_location()
		error := new_err(
			.CANNOT_OPEN_FILE,
			ErrorMessage[.CANNOT_OPEN_FILE],
			errorLocation
		)
		throw_err(error)
		log_err(fmt.tprintf("Error opening file: ", filepath), errorLocation)
		return 0, false
	}
	return handle, true
}


//helper that concats a collections name to the standard collection path.
concat_standard_collection_name :: proc(colFileName: string) -> string {
	return strings.clone(
		fmt.tprintf("%s%s%s", STANDARD_COLLECTION_PATH, colFileName, OST_EXT),
	)
}

//helper to get users input from the command line
get_input :: proc(isPassword: bool) -> string {
	buf := new([1024]byte)
	defer free(buf)
	if isPassword {
		libc.system("stty -echo") //hide input
	} else {
		libc.system("stty echo")
	}
	n, err := os.read(os.stdin, buf[:])
	if err != 0 {
		fmt.printfln("%sINTERNAL ERROR%s: OstrichDB failed to read input from command line.", RED, RESET)
		return ""
	}
	result := strings.trim_right(string(buf[:n]), "\r\n")
	return strings.clone(result)
}


//gets the current date in GMT
get_date_and_time :: proc() -> (gmtDate: string, hour: string, minute: string, second: string) {
	mBuf: [8]byte
	dBuf: [8]byte
	yBuf: [8]byte

	hBuf: [8]byte
	minBuf: [8]byte
	sBuf: [8]byte

	h, min, s := time.clock(time.now())
	y, m, d := time.date(time.now())

	mAsInt := int(m) //month comes back as a type "Month" so need to convert
	// Conversions!!! because everything in Odin needs to be converted... :)

	Y := transmute(i64)y
	M := transmute(i64)m
	D := transmute(i64)d

	H := transmute(i64)h
	MIN := transmute(i64)min
	S := transmute(i64)s


	Month := strconv.append_int(mBuf[:], M, 10)
	Year := strconv.append_int(yBuf[:], Y, 10)
	Day := strconv.append_int(dBuf[:], D, 10)

	Hour := strconv.append_int(hBuf[:], H, 10)
	Minute := strconv.append_int(minBuf[:], MIN, 10)
	Second := strconv.append_int(sBuf[:], S, 10)


	switch (mAsInt)
	{
	case 1:
		Month = "January"
		break
	case 2:
		Month = "February"
		break
	case 3:
		Month = "March"
		break
	case 4:
		Month = "April"
		break
	case 5:
		Month = "May"
		break
	case 6:
		Month = "June"
		break
	case 7:
		Month = "July"
		break
	case 8:
		Month = "August"
		break
	case 9:
		Month = "September"
		break
	case 10:
		Month = "October"
		break
	case 11:
		Month = "November"
		break
	case 12:
		Month = "December"
		break
	}

	Date := strings.concatenate([]string{Month, " ", Day, " ", Year, " "})
	return strings.clone(Date), strings.clone(Hour), strings.clone(Minute), strings.clone(Second)

}


//helper used to append qoutation marks to the beginning and end of a string record values
//if the value already has qoutation marks then it will not append them
append_qoutations :: proc(value: string) -> string {
	if strings.contains(value, "\"") {
		return strings.clone(value)
	}
	return strings.clone(fmt.tprintf("\"%s\"", value))
}

//helper used to append single qoutation marks to the beginning and end of CHAR record values
append_single_qoutations__string :: proc(value: string) -> string {
	if strings.contains(value, "'") {
		return strings.clone(value)
	}
	return strings.clone(fmt.tprintf("'%s'", value))
}

append_single_qoutations__rune :: proc(value: rune) -> string {
	return strings.clone(fmt.tprintf("'%c'", value))
}

trim_qoutations :: proc(value: string) -> string {
	if strings.contains(value, "\"") {
		return strings.clone(strings.trim(value, "\""))
	}
	return strings.clone(value)
}


//helper used for the BENCHMARK command to make sure users input is an integer
string_is_int :: proc(value: string) -> bool {
	val, ok := strconv.parse_int(value)
	return ok

}


//helper used to strip array brackets from a string, used in internal_conversion.odin
strip_array_brackets :: proc(value: string) -> string {
	value := strings.trim_prefix(value, "[")
	value = strings.trim_suffix(value, "]")
	return strings.clone(strings.trim_space(value))
}