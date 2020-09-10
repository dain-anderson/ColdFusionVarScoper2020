/***********************************************************************************************************
 * 	VarScoper2020
 *
 * 	(c) 2020 Dain Anderson (dain.anderson@gmail.com), Bucket Head Media, LLC.
 *
 * 	VarScoper2020 is freely distributable under the MIT license.
 * 	Inspiration taken from Mike Schierberl's VarScoper project.
 *
 * 	For updates, bugs, notes, see:
 * 	https://github.com/dain-anderson/ColdFusionVarScoper2020
 *
 *  Credits:
 *  - Shaded boxes by https://bootsnipp.com/evarevirus (https://bootsnipp.com/snippets/QoR8g)
 *  - "dot dot dot" animation: http://jsfiddle.net/DkcD4/94/ from https://stackoverflow.com/questions/13014808/is-there-anyway-to-animate-an-ellipsis-with-css-animations
 *  - Color pallette from https://coolors.co/e63946-f1faee-a8dadc-457b9d-1d3557
 *
 *  "For nothing will be impossible with God."
 * 								- Luke 1:37
 *************************************************************************************************************/
component {

	THIS.applicationtimeout = createTimeSpan( 0, 12, 0, 0 );
	THIS.clientmanagement = false;
	THIS.setclientcookies = false;
	THIS.sessionmanagement = true;
	THIS.mappings[ '/' ] = "H:\htdocs\tds_dev\";
	THIS.name = "VarScoper2020";
	THIS.sessionTimeout = createTimeSpan( 0, 12, 0, 0 );
	THIS.javaSettings = {
		LoadPaths = [ "/lib/" ],
		reloadOnChange = true
	};

	public void function onRequest( string targetPage = "index.cfm" ) {
		include ARGUMENTS.targetPage;
	}

}