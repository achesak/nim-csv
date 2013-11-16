# Nimrod CSV module.

# Written by Adam Chesak.
# Code released under the MIT open source license.


# Import modules.
import parsecsv
import streams
import strutils


proc parseAll*(csv : string, filenameOut : string, separator : char = ',', quote : char = '\"', escape : char = '\0', skipInitialSpace : bool = true): seq[seq[string]] = 
    ## Parses the CSV and returns it as a sequence of sequences. filenameOut is only used for error messages.
    
    # Put the CSV into a stream.
    var stream : PStringStream = newStringStream(csv)
    
    # Create the CSV parser.
    var csvParser : TCsvParser
    csvParser.open(stream, filenameOut, skipInitialSpace = skipInitialSpace, separator = separator, quote = quote, escape = escape)
    
    # Create the return sequence.
    var csvSeq = newSeq[seq[string]](len(csv.splitLines()))
    
    # Loop through the lines and add them to the sequence.
    var c : int = 0
    while readRow(csvParser):
        
        var csvSeq2 = newSeq[string](len(csvParser.row))
        for i in 0..high(csvParser.row):
            csvSeq2[i] = csvParser.row[i]
        csvSeq[c] = csvSeq2
        c += 1
    
    # Return the parsed CSV.
    return csvSeq


proc readAll*(filename : string, filenameOut : string, separator : char = ',', quote : char = '\"', escape : char = '\0', skipInitialSpace : bool = true): seq[seq[string]] = 
    ## Reads the CSV from the file, parses it, and returns it as a sequence of sequences. filenameOut is only used for error messages.
    
    # Get the data from the file.
    var csv : string = readFile(filename)
    
    # Send the string to parseAll() to parse the CSV.
    return parseAll(csv, filenameOut, separator = separator, quote = quote, escape = escape, skipInitialSpace = skipInitialSpace)


proc stringifyAll*(csv : seq[seq[string]]): string = 
    ## Converts the CSV to a string and returns it.


proc writeAll*(filename : string, csv : seq[seq[string]]): string = 
    ## Converts the CSV to a string and writes it to the file. Returns the CSV as a string.

