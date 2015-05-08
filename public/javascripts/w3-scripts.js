//function loadJSCall(scriptId, scriptSrc) {
//	if (document.getElementsByTagName("head").length < 1) {
//		setTimeout(function () {loadJSCall(scriptId, scriptSrc);}, 100);
//		return;
//	}
//	ibmCommonDynamicNavHeadElement = document.getElementsByTagName("head").item(0);
//	var ibmCommonDynamicNavScriptTag = document.createElement("script");
//	ibmCommonDynamicNavScriptTag.setAttribute("id", scriptId);
//	ibmCommonDynamicNavScriptTag.setAttribute("type", "text/javascript");
//	ibmCommonDynamicNavScriptTag.setAttribute("src", scriptSrc);
//	ibmCommonDynamicNavHeadElement.appendChild(ibmCommonDynamicNavScriptTag);
//}

//loadJSCall("wwwcommon","//www.ibm.com/common/js/ibmcommon.js");

// popup window
function popup( url, type, height, width ) {
newWin=window.open(url,'popupWindow','height='+height+',width='+width+',resizable=yes,menubar=no,status=no,toolbar=no,scrollbars=yes');
newWin.focus();
void(0);
}

function toggle(c,r) {
	var c = document.getElementById(c);
	var r = document.getElementById(r);
	if(c.checked) {r.disabled=false;}
	else {r.checked=false;r.disabled=true;}
}
