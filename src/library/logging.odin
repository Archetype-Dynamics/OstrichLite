package library

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for logging events and errors to the console and to log files.
*********************************************************/


main :: proc() {
	os.make_directory(LOG_DIR_PATH)
	create_log_files()
}


create_log_files :: proc() -> int {
	runtimeFile, runtimeLogOpenError := os.open(RUNTIME_LOG_PATH, os.O_CREATE, 0o666)
	if runtimeLogOpenError != 0 {
	errorLocation:= get_caller_location()
		error := new_err(
			.CANNOT_CREATE_FILE,
			ErrorMessage[.CANNOT_CREATE_FILE],
			errorLocation
		)
		throw_err(error)
		log_err("Error creating OstrichLite runtime log file", errorLocation)
		return -1
	}

	defer os.close(runtimeFile)

	errorFile, errorLogOpenError := os.open(ERROR_LOG_PATH, os.O_CREATE, 0o666)
	if errorLogOpenError != 0 {
	    errorLocation:= get_caller_location()
		error := new_err(
			.CANNOT_CREATE_FILE,
			ErrorMessage[.CANNOT_CREATE_FILE],
			errorLocation
		)
		throw_err(error)
		log_err("Error creating OstrichLite error log file", errorLocation)
		return -1

	}

	os.close(errorFile)
	return 0
}

//###############################|RUNTIME LOGGING|############################################
log_runtime_event :: proc(eventName: string, eventDesc: string) -> int {
	date, h, m, s := get_date_and_time()
	defer delete(date)
	defer delete(h)
	defer delete(m)
	defer delete(s)


	runtimeEventName:= fmt.tprintf("Event Name: %s\n", eventName)
	runtimeEventDesc:= fmt.tprintf("Event Description: %s\n", eventDesc)

	runtimeLogBlock:= strings.concatenate([]string{runtimeEventName, runtimeEventDesc})

	fullLogMessage := strings.concatenate(
		[]string {
			runtimeLogBlock,
			"Event Logged: ",
			date,
			"@ ",
			h,
			":",
			m,
			":",
			s,
			" GMT\n",
			"---------------------------------------------\n",
		},
	)

	runtimeLogData := transmute([]u8)fullLogMessage
	defer delete(runtimeLogData)

	runtimeFile, openSuccess := os.open(RUNTIME_LOG_PATH, os.O_APPEND | os.O_RDWR, 0o666)
	defer os.close(runtimeFile)
	if openSuccess != 0 {
	    errLocation:= get_caller_location()
		log_err("Error opening runtime log file", errLocation)
		return -1
	}


	_, writeSuccess := os.write(runtimeFile, runtimeLogData)
	if writeSuccess != 0 {
	    errLocation := get_caller_location()
		log_err("Error writing to runtime log file", errLocation)
		return -2
	}

	os.close(runtimeFile)
	return 0
}


//###############################|ERROR LOGGING|############################################
log_err :: proc(message: string, location: SourceCodeLocation) -> int {
	date, h, m, s := get_date_and_time()
	defer delete(date)
	defer delete(h)
	defer delete(m)
	defer delete(s)

	errMessageString:= fmt.tprintf("Error: %s\n", message)
	errSourceCodeFile:= fmt.tprintf("Source Code File: %s\n", location.file_path)
	errProcedure:= fmt.tprintf("Procedure: %s\n", location.procedure)
	errLine:= fmt.tprintf("Line: #%d \n", location.line)

	errorLogBlock := strings.concatenate([]string{errMessageString, errSourceCodeFile, errProcedure, errLine})

	fullLog := strings.concatenate(
		[]string {
			errorLogBlock,
			"Error Occured: ",
			date,
			"@ ",
			h,
			":",
			m,
			":",
			s,
			" GMT\n",
			"---------------------------------------------\n",
		},
	)

	errLogData := transmute([]u8)fullLog
	defer delete(errLogData)

	errorFile, openSuccess := os.open(ERROR_LOG_PATH, os.O_APPEND | os.O_RDWR, 0o666)
	if openSuccess != 0 {
		return -1
	}


	_ , writeSuccess := os.write(errorFile, errLogData)
	if writeSuccess != 0 {
		return -2
	}

	defer os.close(errorFile)
	return 0
}