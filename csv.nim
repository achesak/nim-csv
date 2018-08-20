# Nim CSV module.

# Written by Adam Chesak.
# Code released under the MIT open source license.


# Import modules.
import parsecsv
import streams
import strutils


proc checkEnding(csv: string, separator: char): bool = 
    ## Check if the lines end with the separating character.
    
    let lines: seq[string] = csv.splitLines()
    for line in lines:
        if not line.endsWith("" & separator):
            return false
    return true


proc quoteItemIfNecessary(s: string): string =
    ## Quote item if it contains a space and does not start with a quote.
    ## This is ``quoteIfContainsWhite`` but reimplemented to
    ## remove deprecation warning
    
    if find(s, {' ', '\t'}) >= 0 and s[0] != '"':
        return '"' & s & '"'
    else:
        return s


proc parseAll*(
    csv: string, filenameOut: string, separator: char = ',', quote: char = '\"',
    escape: char = '\0', skipInitialSpace: bool = false, skipBlankLast: bool = false
): seq[seq[string]] = 
    ## Parses the CSV and returns it as a sequence of sequences.
    ##
    ## * ``filenameOut`` is only used for error messages.
    ## * If ``skipBlankLast`` is true, then if every line ends with ``separator``
    ##   there will not be a blank field at the end of every row.
    ## * See Nim's ``parsecsv`` docs for information on other parameters.

    var csvSeq: seq[seq[string]] = @[]

    # Clean the CSV: remove blank lines
    var csvLines: seq[string] = csv.splitLines()
    var cleanedLines: seq[string] = @[]
    for line in csvLines:
        if line.strip() != "":
            cleanedLines.add(line)
    var cleanedcsv: string = cleanedLines.join("\n")

    if cleanedcsv == nil or cleanedcsv.strip() == "":
        return csvSeq
    
    # Check if the CSV has a blank field on every row:
    var newcsv: string = cleanedcsv.strip(trailing = true)
    if skipBlankLast and checkEnding(cleanedcsv, separator):
        
        # Remove the last separator from every line.
        var lines: seq[string] = newcsv.splitLines()
        for i in 0..high(lines):
            lines[i] = lines[i][0..len(lines[i])-2]
        newcsv = lines.join("\n")
    
    # Remember which lines ended with an empty item.
    var endings: seq[int] = @[]
    let endlines: seq[string] = newcsv.splitlines()
    for i in 0..high(endlines):
        if checkEnding(endlines[i], separator):
            endings.add(i)

    let stream: StringStream = newStringStream(newcsv)
    var csvParser: CsvParser
    csvParser.open(
        stream, filenameOut, skipInitialSpace = skipInitialSpace,
        separator = separator, quote = quote, escape = escape
    )

    var c: int = 0
    while readRow(csvParser):
        var row = newSeq[string](len(csvParser.row))
        if c in endings:
            row.add("")
        for i in 0..high(csvParser.row):
            row[i] = csvParser.row[i]
        csvSeq.add(row)
        c += 1

    return csvSeq


proc readAll*(
    filename: string, filenameOut: string, separator: char = ',', quote: char = '\"',
    escape: char = '\0', skipInitialSpace: bool = false, skipBlankLast: bool = false
): seq[seq[string]] = 
    ## Reads the CSV from the file, parses it, and returns it as a sequence of sequences.
    ##
    ## * ``filenameOut`` is only used for error messages.
    ## * If ``skipBlankLast`` is true, then if every line ends with ``separator``
    ##   there will not be a blank field at the end of every row.
    ## * See Nim's ``parsecsv`` docs for information on other parameters..
    
    let csv: string = readFile(filename).strip(trailing = true)
    return parseAll(
        csv, filenameOut, separator = separator, quote = quote, escape = escape,
        skipInitialSpace = skipInitialSpace, skipBlankLast = skipBlankLast
    )


proc stringifyAll*(
    csv: seq[seq[string]], separator: string = ",", escapeQuotes: bool = true,
    quoteAlways: bool = false, spaceBetweenFields: bool = false
): string = 
    ## Converts the CSV to a string and returns it.
    ##
    ## * ``separator`` is the string used as the separating character between fields.
    ## * If ``escapeQuotes`` is ``true``, ``"`` will be replaced with ``\"``
    ##   and ``'`` will be replaced with ``\'``.
    ## * If ``quoteAlways`` is ``true``, it will always add quotes around the item.
    ##   If it is ``false``, quotes will only be added if the item contains quotes,
    ##   whitespace, or the separator character.
    ## * If ``spaceBetweenFields`` is ``true``, an extra space will be added after
    ##   the separator character.
    
    var delimiter: string
    if spaceBetweenFields:
      delimiter = separator & " "
    else:
      delimiter = separator
    
    var csvStr: string = ""
    for i in 0..high(csv):
        
        var csvStrRow: string = ""
        for j in 0..high(csv[i]):
            
            # Escape the quotes, if the user wants that.
            var item: string = csv[i][j]
            if escapeQuotes and (item.contains("\"") or item.contains("'")):
                item = item.replace("\"", "\\\"").replace("'", "\\'")
                
            # Quote always if the user wants that, otherwise only do it if necessary.
            if quoteAlways:
                item = "\"" & item & "\""
            elif item.contains("\"") or item.contains("'") or item.contains(separator):
                item = "\"" & item & "\""
            else:
                item = quoteItemIfNecessary(item)

            csvStrRow &= item
            
            # Only add a separator if it isn't the last item.
            if j != high(csv[i]):
                csvStrRow &= delimiter

        csvStr &= csvStrRow
        
        # Only add a newline if it isn't the last row.
        if i != high(csv):
            csvStr &= "\n"

    return csvStr


proc writeAll*(
    filename: string, csv: seq[seq[string]], separator: string = ",",
    escapeQuotes: bool = true, quoteAlways: bool = false,
    spaceBetweenFields: bool = false
): string = 
    ## Converts the CSV to a string and writes it to the file. Returns the CSV as a string.
    ##
    ## * ``separator`` is the string used as the separating character between fields.
    ## * If ``escapeQuotes`` is ``true``, ``"`` will be replaced with ``\"`` and
    ##   ``'`` will be replaced with ``\'``.
    ## * If ``quoteAlways`` is ``true``, it will always add quotes around the item.
    ##   If it is ``false``, quotes will only be added if the item contains quotes,
    ##   whitespace, or the separator character.
    ## * If ``spaceBetweenFields`` is ``true``, an extra space will be added after
    ##   the separator character.
    
    let csvStr: string = stringifyAll(
        csv, separator = separator, escapeQuotes = escapeQuotes,
        quoteAlways = quoteAlways, spaceBetweenFields = spaceBetweenFields
    )
    writeFile(filename, csvStr)
    return csvStr
