package library

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains miscellaneous utility functions.
*********************************************************/

ostrich_art := `
$$$$$$\              $$\               $$\           $$\       $$$$$$$\  $$$$$$$\
$$  __$$\             $$ |              \__|          $$ |      $$  __$$\ $$  __$$\
$$ /  $$ | $$$$$$$\ $$$$$$\    $$$$$$\  $$\  $$$$$$$\ $$$$$$$\  $$ |  $$ |$$ |  $$ |
$$ |  $$ |$$  _____|\_$$  _|  $$  __$$\ $$ |$$  _____|$$  __$$\ $$ |  $$ |$$$$$$$\ |
$$ |  $$ |\$$$$$$\    $$ |    $$ |  \__|$$ |$$ /      $$ |  $$ |$$ |  $$ |$$  __$$\
$$ |  $$ | \____$$\   $$ |$$\ $$ |      $$ |$$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |
 $$$$$$  |$$$$$$$  |  \$$$$  |$$ |      $$ |\$$$$$$$\ $$ |  $$ |$$$$$$$  |$$$$$$$  |
 \______/ \_______/    \____/ \__|      \__| \_______|\__|  \__|\_______/ \_______/
==================================================================================
 %s: %s%s%s
==================================================================================`

//Constants for text colors and styles
RED :: "\033[31m"
BLUE :: "\033[34m"
GREEN :: "\033[32m"
YELLOW :: "\033[33m"
ORANGE :: "\033[38;5;208m"

BOLD :: "\033[1m"
ITALIC :: "\033[3m"
UNDERLINE :: "\033[4m"
BOLD_UNDERLINE :: "\033[4m\033[1m" //:) makes formatting even easier - SchoolyB
RESET :: "\033[0m"


get_ost_version :: proc() -> []u8 {
    data:[]u8
	// data := #load("../../version") //WIll end up need to make some sort of fetch to an endpoint
	return data
}


//used to help with error handling.
get_line_number :: proc(line: int) -> string {
	if line < 1 {
		return "unknown"
	}
	return fmt.tprintf("%d", line)
}

//used to help with error handling.
show_source_file :: proc(file: string) -> string {
	return fmt.tprintln("Source File: %s%s%s", BOLD, file, RESET)
}

show_server_kill_msg :: proc() {
	fmt.printfln(
		"Enter %s'kill'%s or %s'exit'%s to stop the server\n",
		BOLD_UNDERLINE,
		RESET,
		BOLD_UNDERLINE,
		RESET,
	)
}