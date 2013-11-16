# Nimrod CSV module.

# Written by Adam Chesak.
# Code released under the MIT open source license.


# Import modules.
import parsecsv
import streams
import strutils


proc parseAll*(csv : string, filenameOut : string, separator : char = ',', quote : char = '\"', escape : char = '\0', skipInitialSpace : bool = true): seq[seq[string]] = 
    ## Parses the CSV and returns it as a sequence of sequences. filenameOut is only used for error messages. See Nimrod's parsecsv docs for information on other parameters.
    
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
    ## Reads the CSV from the file, parses it, and returns it as a sequence of sequences. filenameOut is only used for error messages. See Nimrod's parsecsv docs for information on other parameters.
    
    # Get the data from the file.
    var csv : string = readFile(filename)
    
    # Send the string to parseAll() to parse the CSV.
    return parseAll(csv, filenameOut, separator = separator, quote = quote, escape = escape, skipInitialSpace = skipInitialSpace)


proc stringifyAll*(csv : seq[seq[string]], escapeQuotes : bool = true, quoteAlways : bool = false): string = 
    ## Converts the CSV to a string and returns it. If escapeQuotes is true, then " will be replaced with \" and ' will be replaced with \'. If quoteAlways is true,
    ## it will always add quotes around the item. If it is false, then quotes will only be added if the item contains quotes or whitespace.
    
    # Loop through the sequence and append the rows to the string.
    var csvStr : string = ""
    for i in 0..high(csv):
        
        var csvStrRow : string = ""
        for j in 0..high(csv[i]):
            
            # Escape the quotes, if the user wants that.
            var item : string = csv[i][j]
            if escapeQuotes and (item.contains("\"") or item.contains("'")):
                item = item.replace("\"", "\\\"").replace("'", "\\'")
                
            # Quote always if the user wants that, otherwise only do it if necessary.
            if quoteAlways:
                item = "\"" & item & "\""
            elif item.contains("\"") or item.contains("'"):
                item = "\"" & item & "\""
            else:
                item = item.quoteIfContainsWhite()
            
            # Add the item.
            csvStrRow &= item
            
            # Only add a comma if it isn't the last item.
            if j != high(csv[i]):
                csvStrRow &= ", "
        
        # Add the row.
        csvStr &= csvStrRow
        
        # Only add a newline if it isn't the last row.
        if i != high(csv):
            csvStr &= "\n"
    
    # Return the stringified CSV.
    return csvStr


proc writeAll*(filename : string, csv : seq[seq[string]], escapeQuotes : bool = true, quoteAlways : bool = false): string = 
    ## Converts the CSV to a string and writes it to the file. Returns the CSV as a string. If escapeQuotes is true, then " will be replaced with \" and
    ## ' will be replaced with \'. If quoteAlways is true, it will always add quotes around the item. If it is false, then quotes will only be added if
    ## the item contains quotes or whitespace.
    
    # Get the stringified CSV.
    var csvStr : string = stringifyAll(csv, escapeQuotes = escapeQuotes, quoteAlways = quoteAlways)
    
    # Write the CSV to the file.
    writeFile(filename, csvStr)
    
    # Return the stringified CSV.
    return csvStr
