component accessors="true" {

	property name="source";
	property name="data";
	property name="functionsAndExpressions";

	VARIABLES.CFMLParser = createObject( "java", "cfml.parsing.CFMLParser" );
	REQUEST.whichFunction = "";

	public varScoper2020 function init( string source='' ){
		Reset();

		if( len( ARGUMENTS.source ) ){
			this.setSource( ARGUMENTS.source );
		}

		return this;
	}

	public void function Reset(){
		VARIABLES.Source = '';
		VARIABLES.Data = '';
		VARIABLES.FunctionsAndExpressions = [];
	}


	public void function setSource( required string source ){

		Reset();

		try {

			VARIABLES.Data = VARIABLES.CFMLParser.parseScriptFile( ARGUMENTS.source ).decomposeScript();

		} catch( any e ){

			if( structKeyExists( URL, 'debug' ) ){
				writeDump( e );abort;
			}

			writeOutput("<span style='background-color:red'>&nbsp;PARSE FAILED&nbsp;</span> #ARGUMENTS.source#<p />");
		}
	}

	public void function setRawSource( required string rawScript ){
		try {
			if( len( trim( ARGUMENTS.rawScript ) ) ){
				VARIABLES.Data = VARIABLES.CFMLParser.parseScript( ARGUMENTS.rawScript ).decomposeScript();
			} else {
				VARIABLES.Data = '';
			}
		} catch( any e ){
			writeDump( ARGUMENTS );
			writeDump( e );abort;
		}
	}

	public void function Go(){

	}

	public any function parseFunctionExpressions( any data='' ){

		if( isSimpleValue( ARGUMENTS.data ) && !len( trim( ARGUMENTS.data ) ) ){
			ARGUMENTS.data = VARIABLES.data;
		}

		for( var element in ARGUMENTS.data ){
			var classType = javacast( "string", element.getClass().getName() );

			if( structKeyExists( URL, 'debug' ) ){
				writeOutput( classType & '<br />' );
			}

			switch( classType ){
				case 'cfml.parsing.cfscript.script.CFAbortStatement': break;
				case 'cfml.parsing.cfscript.script.CFBreakStatement': break;
				case 'cfml.parsing.cfscript.script.CFCase': parseFunctionExpressions( element.getStatements() ); break;
				//TODO: case 'cfml.parsing.cfscript.script.cfCatchClause': break;
				case 'cfml.parsing.cfscript.script.CFCatchStatement': parseFunctionExpressions( element.decomposeScript() ); break;
				case 'cfml.parsing.cfscript.script.CFCompDeclStatement': // this is the component{} wrapper
					try {
						return parseFunctionExpressions( element.getBody().decomposeScript() );// more than 1 function
					} catch( coldfusion.runtime.java.MethodSelectionException e ){
						return parseFunctionExpressions( element.getBody() );// only 1 function
					}
				break;
				case 'cfml.parsing.cfscript.script.CFCompoundStatement': parseFunctionExpressions( element.getStatements() ); break;
				case 'cfml.parsing.cfscript.script.CFContinueStatement': break;
				case 'cfml.parsing.cfscript.script.CFDoWhileStatement':
					parseFunctionExpressions( element.getBody().getStatements() );
				break;
				//TODO: case 'cfml.parsing.cfscript.script.CFEmptyStatement': break; (not sure how to trigger this)
				case 'cfml.parsing.cfscript.script.CFExitStatement': break;
				case 'cfml.parsing.cfscript.script.CFExpressionStatement': // this is what we want, a simple expression

					// TODO: handle other expression types, as found
						// byte FUNCTION	0   ; example: VARIABLES.Populator.populateFromQuery(oAddressType, qAddressType)
						// byte ASSIGNMENT	1   ; example: var x = 1;
						// byte BINARY		2
						// byte LITERAL		3	; example: true;
						// byte IDENTIFIER	4	; example: continue;
						// byte VARIABLE	5
						// byte UNARY		6	; example: i++;
						// byte ARRAYMEMBER	7	; example: x[1];
						// byte NESTED		8
					var expressionType = element.getExpression().getType();

					if( len( REQUEST.whichFunction ) ){

						// this this succeeds, it means the variable was var'd
						try {

							whichVar = element.getExpression().getVar().toString();

							if( !listFindNoCase( REQUEST.whichVars, whichVar ) ){
								REQUEST.whichVars = listAppend( REQUEST.whichVars, whichVar );
							}

							if( structKeyExists( URL, 'debug' ) ){
								writeOutput( REQUEST.whichVars & '<br />' );
							}

						} catch( coldfusion.runtime.java.MethodSelectionException e ){

							try{

								var leftHandExpression = element.getExpression().getLeft().toString();
								var firstWord = trim( reFindNoCase( '^[\w]+', leftHandExpression, 1, true, "one" ).match[1] );

								if( !listFindNoCase( getCFScopes(), firstWord ) && !listFindNoCase( REQUEST.whichVars, firstWord ) ){
									arrayAppend( VARIABLES.functionsAndExpressions[ arrayLen( VARIABLES.functionsAndExpressions )].unscopedArray, {
										"lineNumber": 0,
										"variableContext": element.Decompile(0),
										"variableName": firstWord
									} );
								}
							} catch( any e ){

								// for functions, need to see if there are more nested elements, e.g., cfloop()
								if( expressionType == 0 ){

									aExpressions = element.decomposeExpression();

									if( isArray( aExpressions ) && arrayLen( aExpressions ) ){
										parseFunctionExpressions( aExpressions );
									}
								}

								// if( !listFind( '0,1,3,4,6,7', expressionType ) ){
								// 	writeDump( expressionType );
								// 	writeOutput('<br />');
								// 	writeDump( element );
								// 	writeOutput('<br />');
								// 	writeDump( element.decomposeExpression()[1].Decompile(0) );
								// 	writeOutput('<br />');
								// 	writeDump( element.decomposeScript() );
								// 	writeOutput('<br />');
								// 	writeDump( element.getExpression().toString() );abort;
								// }
							}
						} catch( any e ){
							writeDump( 111 );
							writeDump( element );
							writeDump( e );abort;
						}
					}
				break;
				case 'cfml.parsing.cfscript.script.CFForInStatement':
					try {
						whichVar = element.getVariable().getVar().getName();
						if( !listFindNoCase( REQUEST.whichVars, whichVar ) ){
							REQUEST.whichVars = listAppend( REQUEST.whichVars, whichVar );
						}
					} catch( coldfusion.runtime.java.MethodSelectionException e ){
						var firstWord = trim( reFindNoCase( '^[\w]+', element.getVariable(), 1, true, "one" ).match[1] );
						try{
							if( !listFindNoCase( getCFScopes(), firstWord ) && !listFindNoCase( REQUEST.whichVars, firstWord ) ){
								arrayAppend( VARIABLES.functionsAndExpressions[ arrayLen( VARIABLES.functionsAndExpressions )].unscopedArray, {
									"lineNumber": 0,
									"variableContext": "#element.getVariable()# in for( #element.getVariable()# in #element.getStructure().toString()# )",
									"variableName": firstWord
								} );
							}
						} catch( any e ){
							writeOutput("Function, #REQUEST.whichFunction#, was skipped.<br />");
						}
					} catch( any e ){
						// this means that 'element.getVariable().getVar().getName()' didn't work, and it usually means there's something wrong in the code, alert them to this fact:
						arrayAppend( VARIABLES.functionsAndExpressions[ arrayLen( VARIABLES.functionsAndExpressions )].unscopedArray, {
							"lineNumber": 0,
							"variableContext": "#element.getVariable().Decompile(0)# (investigate usage)",
							"variableName": ""
						} );
					}

					parseFunctionExpressions( element.decomposeScript() );
				break;
				case 'cfml.parsing.cfscript.script.CFForStatement':
					if( len( REQUEST.whichFunction ) ){
						try {
							whichVar = element.getInit().getVar().toString();
							if( !listFindNoCase( REQUEST.whichVars, whichVar ) ){
								REQUEST.whichVars = listAppend( REQUEST.whichVars, whichVar );
							}
						} catch( coldfusion.runtime.java.MethodSelectionException e ){
							try{
								// if( javaCast( 'string', element.getInit() ) != '' ){ // shorthand iterators won't appear for(; i<val; i++)
									var leftHandExpression = element.getInit().getLeft().toString();
									var firstWord = trim( reFindNoCase( '^[\w]+', leftHandExpression, 1, true, "one" ).match[1] );
									try{
										if( !listFindNoCase( getCFScopes(), firstWord ) && !listFindNoCase( REQUEST.whichVars, firstWord ) ){
											arrayAppend( VARIABLES.functionsAndExpressions[ arrayLen( VARIABLES.functionsAndExpressions )].unscopedArray, {
												"lineNumber": 0,
												"variableContext": "#firstWord# in for( #element.getInit().Decompile(0)# ...",
												"variableName": firstWord
											} );
										}
									} catch( any e ){
										writeOutput("Function, #REQUEST.whichFunction#, was skipped.<br />");
									}

								// }
							} catch( any e ){
								// writeDump( element.getInit().getLeft().toString() );abort;
								writeDump( 456 );
								writeDump( element );
								writeDump( element.Decompile(0) );
								writeDump( e );abort;
							}
						} catch( coldfusion.runtime.UninitializedValueException e ){
							// shorthand iterators won't appear for(; i<val; i++)
							continue;
						} catch( any e ){
							writeDump( 888 );
							writeDump( element );
							writeDump( element.Decompile(0) );
							writeDump( e );abort;
						}

						parseFunctionExpressions( element.getBody().decomposeScript() );
					}
				break;
				case 'cfml.parsing.cfscript.script.CFFuncDeclStatement': // this is a function{} wrapper
					// get the current function name
					var functionName = element.getName().toString();

					if( structKeyExists( URL, 'debug' ) ){
						writeOutput( functionName & '<br />' );
					}

					// cheating
					REQUEST.whichVars = '';
					REQUEST.whichFunction = functionName;

					// prime the structure key as an array to list function-specific expressions of interest
					arrayAppend( VARIABLES.functionsAndExpressions, {
						"functionName": functionName,
						"lineNumber": 0,
						"unscopedArray": []
					} );

					parseFunctionExpressions( element.decomposeScript(), functionName );

					// if no function-specific expressions of interest were found, remove the key
					if( !arrayLen( VARIABLES.functionsAndExpressions[ arrayLen( VARIABLES.functionsAndExpressions ) ].unscopedArray ) ){
						arrayDeleteAt( VARIABLES.functionsAndExpressions, arrayLen( VARIABLES.functionsAndExpressions ) );
					}
				break;
				//TODO: cfml.parsing.cfscript.script.CFFunctionParameter: break;
				case 'cfml.parsing.cfscript.script.CFIfStatement': parseFunctionExpressions( element.decomposeScript() ); break;
				case 'cfml.parsing.cfscript.script.CFImportStatement': break;
				case 'cfml.parsing.cfscript.script.CFIncludeStatement': break;
				case 'cfml.parsing.cfscript.script.CFLockStatement': break;
				case 'cfml.parsing.cfscript.script.CFParamStatement': break;
				//TODO: case 'cfml.parsing.cfscript.script.CFParsedAttributeStatement': break;
				//TODO: case 'cfml.parsing.cfscript.script.CFParsedStatement': break;
				case 'cfml.parsing.cfscript.script.CFPropertyStatement': break;
				case 'cfml.parsing.cfscript.script.CFReThrowStatement': break;
				case 'cfml.parsing.cfscript.script.CFReturnStatement': break; //TODO: do we need to check for expressions here?
				//TODO: case 'cfml.parsing.cfscript.script.CFScriptStatement': break;
				//TODO: case 'cfml.parsing.cfscript.script.CFStatementResult': break;
				case 'cfml.parsing.cfscript.CFFunctionExpression':
					// this is the query name in a cfloop(query=foo)
					// try{
					// 	var firstWord = element.decomposeExpression()[1].getName();
					// 	if( findNoCase("cfloop", element.Decompile(0) ) ){ // ugh.
					// 		if( !listFindNoCase( getCFScopes(), firstWord ) && !listFindNoCase( REQUEST.whichVars, firstWord ) ){
					// 			arrayAppend( VARIABLES.functionsAndExpressions[ arrayLen( VARIABLES.functionsAndExpressions )].unscopedArray, {
					// 				"lineNumber": 0,
					// 				"variableContext": "#firstWord# cfloop(query=#firstWord#...",
					// 				"variableName": firstWord
					// 			} );
					// 		}
					// 	}
					// } catch( coldfusion.runtime.java.MethodSelectionException e ){
					// 	// don't do anything
					// } catch( any e ){
					// 	// writeOutput("Function, #REQUEST.whichFunction#, was skipped.<br />");
					// }
					if( javaCast( 'string', element.getBody() ) != ''){
						var aBody = element.getBody().decomposeScript();
						if( isArray( aBody ) && arrayLen( aBody) ){
							parseFunctionExpressions( element.getBody().decomposeScript() );
						}
					}
				break;
				case 'cfml.parsing.cfscript.script.CFSwitchStatement': parseFunctionExpressions( element.getCases() ); break;
				case 'cfml.parsing.cfscript.script.CFThreadStatement': break; //TODO: do we need to check for thread var name?
				case 'cfml.parsing.cfscript.script.CFThrowStatement': break;
				case 'cfml.parsing.cfscript.script.CFTagThrowStatement': break; // this is only for CFML docs
				case 'cfml.parsing.cfscript.script.CFTransactionStatement':
					// inline transaction block does not have a body to parse
					if( javaCast( 'string', element.getBody() ) != ''){
						try {
							parseFunctionExpressions( element.getBody().decomposeScript() );
						} catch( any e ){
							writeDump( 123 );
							writeDump( element.getBody() );abort;
						}
					}
				break;
				case 'cfml.parsing.cfscript.script.CFTryCatchStatement':
					parseFunctionExpressions( element.getBody().decomposeScript() );
					parseFunctionExpressions( element.getCatchStatements() );
					if( javaCast( "string", element.getFinallyStatement() ) != "" ){
						parseFunctionExpressions( element.getFinallyStatement().decomposeScript() );
					}
				break;
				case 'cfml.parsing.cfscript.script.CFWhileStatement':
					parseFunctionExpressions( element.getBody().decomposeScript() );
				break;
				//TODO: case 'cfml.parsing.cfscript.script.ExceptionVarHandler': break; (not implemented by cfml.parsing)
				//TODO: case 'cfml.parsing.cfscript.script.IncludeStatement': break;
				//TODO: case 'cfml.parsing.cfscript.script.JavaBlock': break;
				//TODO: case 'cfml.parsing.cfscript.script.userDefinedFunction': break;
				case 'cfml.parsing.cfscript.script.CFMLFunctionStatement':
					//TODO: probably need to check variables here for savecontent, etc...
					try {
						parseFunctionExpressions( element.getBody().decomposeScript() );

					} catch( any e ){
						// setting requesttimeout=VARIABLES.CurrentAccount.getLongRequestTimeout();
						continue;
						// writeDump( element.Decompile(0) );abort;
					}
				break;
				case 'java.lang.String':
					// writeDump( element );abort;
					continue;
				break;
				case 'cfml.parsing.cfscript.CFFullVarExpression': break;
				default:
					writeDump( 321 );
					writeDump( classType );abort;
			}
		}
	}

	public string function getCFScopes(){
		return "application,arguments,attributes,caller,cfcatch,cffile,cgi,cfhttp,client,cookie,flash,form,local,request,server,session,super,this,thistag,thread,thread-local,url,variables";
	}

}