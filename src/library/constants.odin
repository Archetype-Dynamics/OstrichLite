package library



METADATA_START :: "@@@@@@@@@@@@@@@TOP@@@@@@@@@@@@@@@\n"
METADATA_END :: "@@@@@@@@@@@@@@@BTM@@@@@@@@@@@@@@@\n"

METADATA_HEADER: []string : {
	METADATA_START,
	"# Encryption Status: %es\n",
	"# File Format Version: %ffv\n",
	"# Permission: %perm\n", //Read-Only/Read-Write/Inaccessible
	"# Date of Creation: %fdoc\n",
	"# Date Last Modified: %fdlm\n",
	"# File Size: %fs Bytes\n",
	"# Checksum: %cs\n",
	METADATA_END,
}

SYS_MASTER_KEY := []byte {
	0x8F,
	0x2A,
	0x1D,
	0x5E,
	0x9C,
	0x4B,
	0x7F,
	0x3A,
	0x6D,
	0x0E,
	0x8B,
	0x2C,
	0x5F,
	0x9A,
	0x7D,
	0x4E,
	0x1B,
	0x3C,
	0x6A,
	0x8D,
	0x2E,
	0x5F,
	0x7C,
	0x9B,
	0x4A,
	0x1D,
	0x8E,
	0x3F,
	0x6C,
	0x9B,
	0x2A,
	0x5,
}

//SERVER DYNAMIC ROUTE CONSTANTS
C_DYNAMIC_BASE :: "/c/*"
CL_DYNAMIC_BASE :: "/c/*/cl/*"
R_DYNAMIC_BASE :: "/c/*/cl/*/r/*"
R_DYNAMIC_TYPE_QUERY :: "/c/*/cl/*/r/*?type=*" //Only used for creating a new record without a value...POST request
R_DYNAMIC_TYPE_VALUE_QUERY :: "/c/*/cl/*/r/*?type=*&value=*" //Used for setting an already existing records value...PUT request




//Shit From The OstrichDB CLI Might not need???
//Defines is a command line constant pfor file paths
//Read more about this here: https://odin-lang.org/docs/overview/#command-line-defines
DEV_MODE :: #config(DEV_MODE, false)

//Conditional file path constants thanks to the install debacle of Feb 2025 - Marshall
//See more here: https://github.com/Solitude-Software-Solutions/OstrichDB/issues/223
//DO NOT TOUCH MF - Marshall
when DEV_MODE == true {
	ROOT_PATH :: "./"
	TMP_PATH :: "./tmp/"
	PRIVATE_PATH :: "./private/"
	PUBLIC_PATH :: "./public/"
	STANDARD_COLLECTION_PATH :: "./public/standard/"
	USERS_PATH :: "./private/users/"
	BACKUP_PATH :: "./public/backups/"
	SYSTEM_CONFIG_PATH :: "./private/ostrich.config.ostrichdb"
	ID_PATH :: "./private/ids.ostrichdb"
	BENCHMARK_PATH :: "./private/benchmark/"
	LOG_DIR_PATH :: "./logs/"
	RUNTIME_LOG_PATH :: "./logs/runtime.log"
	ERROR_LOG_PATH :: "./logs/errors.log"
	SERVER_LOG_PATH :: "./logs/server_events.log"
	QUARANTINE_PATH :: "./public/quarantine/"
	RESTART_SCRIPT_PATH :: "../scripts/restart.sh"
	BUILD_SCRIPT_PATH :: "../scripts/local_build_run.sh"
} else {
	ROOT_PATH :: "./.ostrichdb/"
	TMP_PATH :: "./.ostrichdb/tmp/"
	PRIVATE_PATH :: "./.ostrichdb/private/"
	PUBLIC_PATH :: "./.ostrichdb/public/"
	STANDARD_COLLECTION_PATH :: "./.ostrichdb/public/standard/"
	USERS_PATH :: "./private/users/"
	BACKUP_PATH :: "./.ostrichdb/public/backups/"
	SYSTEM_CONFIG_PATH :: "./.ostrichdb/private/config.ostrichdb"
	ID_PATH :: "./.ostrichdb/private/ids.ostrichdb"
	BENCHMARK_PATH :: "./.ostrichdb/private/benchmark/"
	LOG_DIR_PATH :: "./.ostrichdb/logs/"
	RUNTIME_LOG_PATH :: "./.ostrichdb/logs/runtime.log"
	ERROR_LOG_PATH :: "./.ostrichdb/logs/errors.log"
	SERVER_LOG_PATH :: "./.ostrichdb/logs/server_events.log"
	QUARANTINE_PATH :: "./.ostrichdb/public/quarantine/"
	RESTART_SCRIPT_PATH :: "./.ostrichdb/restart.sh"
	BUILD_SCRIPT_PATH :: "./.ostrichdb/build_run.sh"
}

//Non-changing PATH CONSTANTS
FFVF_PATH :: "ost_file_format_version.tmp"
SYSTEM_CONFIG_CLUSTER :: "OSTRICH_SYSTEM_CONFIGS"
CLUSTER_ID_CLUSTER :: "CLUSTER__IDS"
USER_ID_CLUSTER :: "USER__IDS"
OST_EXT :: ".ostrichdb"
VERBOSE_HELP_FILE :: "../src/core/help/docs/verbose/verbose.md"
SIMPLE_HELP_FILE :: "../src/core/help/docs/simple/simple.md"
GENERAL_HELP_FILE :: "../src/core/help/docs/general/general.md"
CLPS_HELP_FILE :: "../src/core/help/docs/clps/clps.txt"
