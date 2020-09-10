<cfscript>
param name="URL.scanPath" default="";
param name="URL.showClean" default="0";

URL.showClean = val( URL.showClean );

include "header.cfm";

dirStart = expandPath( '/' );
if( len( trim( URL.scanPath ) ) ){
	if( fileExists( URL.scanPath ) || directoryExists( URL.scanPath ) ){
		dirStart = URL.scanPath;
	} else {
		dirStart = expandPath( URL.scanPath );
		if( !directoryExists( dirStart ) ){
			dirStart = expandPath( '/' );
		}
	}
} else {
	URL.scanPath = dirStart;
}

writeOutput( "<script>$('##inputPath').val('#encodeForJavaScript( URL.scanPath )#');</script>" );

if( isStruct( URL ) && !structKeyExists( URL, "submit" ) ){
	abort;
}

startTime = getTickCount();

oVarScoper2020 = new models.VarScoper2020();

if( structKeyExists( URL, "flush" ) ){
	structClear( SESSION );
}

writeOutput( "<div class='box effect1 p-3 resultsbox rounded'><span class='font-weight-bold'>Scanning directory #encodeForHTML( dirStart )#</span>" );
writeOutput( "<div id='loading' style='font-size:84pt'><span class='one'>.</span><span class='two'>.</span><span class='three'>.</span></div>" );

filesScanned = 0;
filesParsed = 0;
countOfUnscopedVariables = 0;
fileName = getFileFromPath( dirStart );
directoryName = getDirectoryFromPath( dirStart );
directoryListing = directoryList( path=directoryName, recurse=true, type="file", filter=fileName );

for( fileFullPath in directoryListing ){

	filesScanned++;

	fileContent = fileRead( fileFullPath );
	isCFM = findNoCase( '</cffunction>', fileContent ); // TODO:this is probably insufficient
	hasCFScript = findNoCase( '</cfscript>', fileContent ); // TODO:this is probably insufficient
	fileExtension = listLast( fileFullPath, '.' );

	if( fileExtension != 'cfc' ){
		continue;
	}

	filesParsed++;

	// skip "clean" files
	if( structKeyExists( SESSION, 'cleanFiles' ) && structKeyExists( SESSION.cleanFiles, fileFullPath ) && URL.showClean ){
		if( URL.showClean ){
			writeOutput("<span style='background-color:palegreen' class='rounded'>&nbsp;ALREADY CHECKED&nbsp;</span> #fileFullPath#<p />");
		}
		continue;
	} else if (! structKeyExists( SESSION, 'cleanFiles' ) ){
		SESSION.cleanFiles = [:];
	}

	// use legacy VarScoper to process non-cfscript-based files
	if( isCFM && !hasCFScript ){
		whichLexer = "<span style='background-color:lavender;' class='rounded'>&nbsp;CFML&nbsp;</span>";
		oVarScoper = new varscoper.varScoper( fileParseText = fileContent, parseCFscript = true );
		oVarScoper.runVarscoper();

		Results = oVarScoper.getResultsArray();
	} else if( isCFM && hasCFScript ){
		whichLexer = "<span style='background-color:LemonChiffon;' class='rounded'>&nbsp;CFML + CFScript&nbsp;</span>";
		Results = [];
		Results2 = [];

		oVarScoper = new varscoper.varScoper( fileParseText = fileContent, parseCFscript = true );
		oVarScoper.runVarscoper();

		Results = oVarScoper.getResultsArray();

		CFScripts = reMatchNoCase( '<cfscript>(.*?)<\/cfscript>', fileContent );
		if( isArray( CFScripts ) && arrayLen( CFScripts ) ){
			for( script in CFScripts ){
				script = replace( script, "<cfscript>", "one" );
				script = replace( script, "</cfscript>", "one" );
				oVarScoper2020.setRawSource( script );
				oVarScoper2020.parseFunctionExpressions();

				Results2 = oVarScoper2020.getFunctionsAndExpressions();
				oVarScoper2020.Reset();
			}
		}
		if( arrayLen( Results ) && arrayLen( Results2 ) ){
			for( Element in Results2 ){
				arrayAppend( Results, Element )
			}
		} else if( arrayLen( Results2 ) ){
			Results = Results2;
		}
	} else {
		whichLexer = "<span style='background-color:LavenderBlush;'>&nbsp;CFScript&nbsp;</span>";
		oVarScoper2020.setSource( fileFullPath );
		oVarScoper2020.parseFunctionExpressions();

		Results = oVarScoper2020.getFunctionsAndExpressions();
	}

	if( ( isStruct( Results ) && structIsEmpty( Results) ) || ( isArray( Results ) && arrayIsEmpty( Results ) ) ){
		if( structKeyExists( SESSION, 'cleanFiles' ) && !structKeyExists( SESSION.cleanFiles, fileFullPath ) ){
			writeOutput("<span style='background-color:palegreen'>&nbsp;OK&nbsp;</span> #fileFullPath# #whichLexer#<p />");
			SESSION.cleanFiles[ fileFullPath ] = true;
		}
	} else {
		writeOutput("<div class='box effect2 p-3 varbox rounded'><span style='background-color:salmon'>&nbsp;UNSCOPED VARS FOUND&nbsp;</span> #fileFullPath# #whichLexer#<div class='p-3'>");
		for( func in Results ){
			if( arrayLen( func.UnscopedArray ) ){
				temp = '';
				for( unscoped in func.UnscopedArray ){
					if( temp != unscoped.variableName ){
						countOfUnscopedVariables++;
						writeOutput( '&nbsp;&nbsp;&nbsp;&nbsp;#countOfUnscopedVariables#:#func.functionName#() <kbd>&nbsp;#unscoped.variableName#&nbsp;</kbd> in expression <kbd>#encodeForHTML( left( trim( unscoped.variableContext ), 50 ) )#</kbd><p/>' );
					}
					temp = unscoped.variableName;
				}
			}
		}
		writeOutput('</div></div>')
	}

	cfflush();
}
endTime = getTickCount();
writeOutput("Time:#(endTime-startTime)#ms<br />" );
writeOutput("Files:#filesScanned#<br />");
writeOutput("CFCs:#filesParsed#<br />");
</cfscript>
</div>
</body>
</html>