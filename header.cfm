<!DOCTYPE html>
<html lang="en-us">
<head>
<title>VarScoper 2020</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="keywords" content="ColdFusion, CFML, Lucee, BlueDragon, TagServlet, VarScoper, Unscoped Variables" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js" integrity="sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj" crossorigin="anonymous"></script>
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css" integrity="sha384-9aIt2nRpC12Uk9gS9baDl411NQApFmC26EwAOH8WgZl5MYYxFfc+NcPb1dKGj7Sk" crossorigin="anonymous">
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js" integrity="sha384-OgVRvuATP1z7JjHLkuOU7Xw704+h835Lr+6QL9UvYjZE3Ipu6Tp75j7Bh/kR0JKI" crossorigin="anonymous"></script>
<script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
<style>
body {background:#457b9d}
.topbox{background:#a8dadc}
.resultsbox{background:#a8dadc;}
.varbox{background:#f1faee}
.my-btn{background:#1d3557;color:#f1faee;}
.my-btn:hover{color:#f1faee;}
.box h3{text-align:center;position:relative;top:80px}
.box{margin:40px auto}
.effect1{-webkit-box-shadow:0 10px 6px -6px #1d3557;-moz-box-shadow:0 10px 6px -6px #1d3557;box-shadow:0 10px 6px -6px #1d3557}
.effect2{position:relative}
.effect2:before, .effect2:after{z-index:-1;position:absolute;content:"";bottom:15px;left:10px;width:50%;top:80%;max-width:300px;background:#1d3557;-webkit-box-shadow:0 15px 10px #1d3557;-moz-box-shadow:0 15px 10px #1d3557;box-shadow:0 15px 10px #1d3557;-webkit-transform:rotate(-3deg);-moz-transform:rotate(-3deg);-o-transform:rotate(-3deg);-ms-transform:rotate(-3deg);transform:rotate(-3deg)}
.effect2:after{-webkit-transform:rotate(3deg);-moz-transform:rotate(3deg);-o-transform:rotate(3deg);-ms-transform:rotate(3deg);transform:rotate(3deg);right:10px;left:auto}
.one{opacity:0;-webkit-animation:dot 1.3s infinite;-webkit-animation-delay:0.0s;animation:dot 1.3s infinite;animation-delay:0.0s}
.two{opacity:0;-webkit-animation:dot 1.3s infinite;-webkit-animation-delay:0.2s;animation:dot 1.3s infinite;animation-delay:0.2s}
.three{opacity:0;-webkit-animation:dot 1.3s infinite;-webkit-animation-delay:0.3s;animation:dot 1.3s infinite;animation-delay:0.3s}
@-webkit-keyframes dot{0%{opacity:0}50%{opacity:0}100%{opacity:1}}
@keyframes dot{0%{opacity:0}50% {opacity:0}100% {opacity:1}}
#loading{color:#f1faee;text-align:center;position:relative;top:130px;z-index:0;margin-top:-170px}
</style>
</head>
<body>
<div class="container-fluid">
<div class='box effect1 p-4 topbox rounded'>
	<h4>VarScoper 2020</h4>
	<form>
	<div class="row">
		<div class="col-sm-8">
			<input class="form-control" id="inputPath" name="scanPath" placeholder="Path to files">
			<small class="p-1 text-muted">Relatives are expanded. Absolutes are attempted. Empty scans from webroot. Individual files accepted.</small>
		</div>
		<div class="col-sm-4">
			<label class="p-2"><input type="checkbox" name="showClean" value="1" <cfif structKeyExists( URL, 'showClean' ) && URL.showClean>checked="checked"</cfif>> Show clean files</label>
		</div>
	</div>
	<button type="submit" class="btn my-btn rounded" name="submit">Scan</button>
	</form>
</div>