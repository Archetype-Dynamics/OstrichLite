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
