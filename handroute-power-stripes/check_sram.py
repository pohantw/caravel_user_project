#!/usr/bin/env python3
#
# Script to read a GDS file, and replace a single cell structure with a cell of
# the same name from a different GDS file.  If a checksum is provided, then
# the cell contents will be checked against the checksum before allowing the
# replacement.  The checksum is just the sum of the length of all GDS records in
# the cell.  A checksum can be determined by running this routine once without
# supplying a checksum;  the checksum will be calculated and printed.
#
# There are no checks to ensure that the replacement cell is in any way compatible
# with the existing cell.  Validation must be done independently.  This script is
# only a simple GDS data compositor.
import os
import sys
def usage():
    print(
        'check_sram.py <sram_cell_name> <path_to_input_gds> [-ref_checksum=<checksum>]')
if __name__ == '__main__':
    debug = False
    if len(sys.argv) == 1:
        print("No options given to check_sram.py.")
        usage()
        sys.exit(0)
    optionlist = []
    arguments = []
    for option in sys.argv[1:]:
        if option.find('-', 0) == 0:
            optionlist.append(option)
        else:
            arguments.append(option)
    if len(arguments) < 2 or len(arguments) > 3:
        print("Wrong number of arguments given to change_gds_cell.py.")
        usage()
        sys.exit(0)
    checksum = '0'
    for option in optionlist:
        if option == '-debug':
            debug = True
        elif option.split('=')[0] == '-ref_checksum':
            checksum = option.split('=')[1]
    try:
        checksum = int(checksum)
    except:
        print('Checksum must evaluate to an integer.')
        sys.exit(1)
    cellname = arguments[0]
    input_gds = arguments[1]
    input_gdsdir = os.path.split(input_gds)[0]
    gdsinfile = os.path.split(input_gds)[1]
    if debug:
        print('Reading GDS file for ' + input_gds)
    with open(input_gds, 'rb') as ifile:
        gdsdata = ifile.read()
    datalen = len(gdsdata)
    dataptr = 0
    incell = False
    cellchecksum = 0
    datastart = dataend = -1
    while dataptr < datalen:
        # Read stream records up to any structure, then check for structure name
        bheader = gdsdata[dataptr:dataptr + 2]
        reclen = int.from_bytes(bheader, 'big')
        if reclen == 0:
            print('Error: found zero-length record at position ' + str(dataptr))
            break
        rectype = gdsdata[dataptr + 2]
        datatype = gdsdata[dataptr + 3]
        brectype = rectype.to_bytes(1, byteorder='big')
        bdatatype = datatype.to_bytes(1, byteorder='big')
        if rectype == 5:  # beginstr
            saveptr = dataptr
        elif rectype == 6:  # strname
            if datatype != 6:
                print('Error: Structure name record is not a string!')
                sys.exit(1)
            bstring = gdsdata[dataptr + 4: dataptr + reclen]
            # Odd length strings end in null byte which needs to be removed
            if bstring[-1] == 0:
                bstring = bstring[:-1]
            strname = bstring.decode('ascii')
            if strname == cellname:
                if debug:
                    print('Cell ' + cellname + ' found at position ' + str(saveptr))
                datastart = saveptr
                incell = True
            elif debug:
                print('Cell ' + strname + ' position ' + str(dataptr) + ' (copied)')
        elif rectype == 7:  # endstr
            if incell:
                incell = False
                cellchecksum = cellchecksum + reclen
                dataend = dataptr + reclen
                if debug:
                    print('Cell ' + cellname + ' ends at position ' + str(dataend))
                    print('Cell ' + cellname + ' checksum is ' + str(cellchecksum))
        # Find checksum (sum of length of all records in the cell of interest)
        if incell:
            cellchecksum = cellchecksum + reclen
        # Advance the pointer past the data
        dataptr += reclen
    if datastart == -1 or dataend == -1:
        print('Failed to find the cell data for ' + cellname)
        sys.exit(1)
    if checksum != 0:
        if cellchecksum == checksum:
            print(cellname + ' matches checksum ' + str(checksum))
        else:
            # print(cellname + ' at ' + str(datastart) + ' to ' + str(dataend) + ' has checksum ' + str(cellchecksum) +
            print(cellname + ' has checksum ' + str(cellchecksum) +
                  ' != ' + str(checksum) + ' (checksum failure)')
            sys.exit(1)
    else:
        print(cellname + ' ' + str(cellchecksum))
    exit(0)