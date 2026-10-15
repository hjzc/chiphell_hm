
function BJAJSZGlobalVariable() {
    this.blacklist = new Array();
    this.appThemeMode = -1;
    this.uatype = 0;
    this.themedoing = false;
    this.themeUpdateCount = 0;
    this.images = new Array();
    this.imageCount = 0;
    this.domReady = false;
    this.isHandleBlacklist = false;
    this.handleBlacklistCount = 0;
    this.callBackList = new Array();
    this.callBackMap = new Map();
    this.src = '';
    this.backNavObject = new Object();
}

function _bja_safeInitVars() {
    try {
        if (!window.jszGVars) {
            window.jszGVars = new BJAJSZGlobalVariable()
            window.jszGVars.src = BJA_GetURL()
        }
    } catch(e) {}
}

function BJA_GetURL() {
    var turl = null;
    try {
        turl = window.location.href
    } catch(e) {}
    if (!turl) {
        try {
            turl = self.location.href
        } catch(e) {}
    }
    if (!turl) {
        try {
            turl = document.URL
        } catch(e) {}
    }
    return turl
}
function BJA_getAbsUrl(url) {
    var ret = null;
    if (url != null) {
        var weburl = BJA_GetURL();
        if (weburl != null) {
            try {
                var wURL = new URL(url, weburl);
                if (wURL != null) {
                    ret = wURL.href
                }
            } catch(e) {}
        }
    }
    return ret
}
function BJA_getEntireUrl(url, weburl) {
    var ret = null;
    if (url == null) {
        return ret
    }
    if (url.toLowerCase().indexOf('http') == 0) {
        return url
    }
    if (weburl != null) {
        try {
            var wURL = new URL(url, weburl);
            if (wURL != null) {
                ret = wURL.href
            }
        } catch(e) {}
    }
    return ret
}
function BJA_DocumentBody() {
    var bd = document.body;
    if (!bd) {
        var bodys = document.getElementsByTagName("body");
        if (!bodys || bodys.length <= 0) {
            bd = false
        } else {
            bd = bodys[0]
        }
    }
    return bd
}
function BJA_DocumentHead() {
    var header = false;
    var heads = [];
    try {
        heads = document.getElementsByTagName('head')
    } catch(ex) {
        heads = []
    }
    if (heads && heads.length > 0) {
        header = heads[0]
    }
    return header
}
function BJA_CreateStyleNode(css) {
    var styleElem = false;
    if (css) {
        try {
            var s = document.createElement('style');
            s.setAttribute('type', 'text/css');
            s.innerHTML = "";
            s.appendChild(document.createTextNode(css));
            if (s) {
                styleElem = s
            }
        } catch(e) {
            styleElem = false
        }
    }
    return styleElem
}
function BJA_AddStyle(element, css) {
    var styleElem = false;
    if (element) {
        styleElem = BJA_CreateStyleNode(css);
        if (styleElem) {
            try {
                styleElem = element.appendChild(styleElem);
                if (!styleElem) {
                    styleElem = false
                }
            } catch(e) {
                styleElem = false
            }
        }
    }
    return styleElem
}
function BJA_AddStyleAtHead(css) {
    var header = BJA_DocumentHead();
    if (header) {
        ret = BJA_AddStyle(header, css)
    }
    return ret
}
function BJA_ele_getText(el) {
    var r = null;
    try {
        if (el) {
            r = el.text;
            r = r.trim()
        }
    } catch(e) {
        r = null
    }
    return r
}
function BJA_ele_setStringAttribute(el, name, strValue) {
    var r = 0;
    try {
        if (el && name && strValue) {
            el.setAttribute(name, strValue);
            r = 1
        }
    } catch(e) {
        r = 0
    }
    return r
}
function BJA_ele_setIntAttribute(el, name, intvalue) {
    var r = 0;
    try {
        if (el && name) {
            var vv = "" + intvalue;
            el.setAttribute(name, vv);
            r = 1
        }
    } catch(e) {
        r = 0
    }
    return r
}
function BJA_ele_hasAttribute(el, name) {
    var r = false;
    if (el && name) {
        r = el.hasAttribute(name)
    }
    return r
}
function BJA_ele_getStringAttribute(el, name) {
    var r = null;
    try {
        if (el && name) {
            if (BJA_ele_hasAttribute(el, name)) {
                r = el.getAttribute(name);
                if (r && BJA_isString(r)) {} else {
                    r = null
                }
            }
        }
    } catch(e) {
        r = null
    }
    return r
}
function BJA_ele_getIntAttribute(el, name) {
    var r = BJA_ele_getStringAttribute(el, name);
    if (r && (r != null)) {
        r = BJA_parseInt(r);
        if (r === false) {
            r = null
        }
    } else {
        r = null
    }
    return r
}
function BJA_nodeForXPath(xmlDom, xpath) {
    var node = null;
    if (!xmlDom) {
        xmlDom = document
    }
    if (typeof xmlDom.evaluate != 'undefined') {
        var result = xmlDom.evaluate(xpath, xmlDom, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
        if (result != null) {
            node = result.singleNodeValue
        }
    }
    return node
}
function BJA_nodesForXPath(xmlDom, xpath) {
    var nodes = [];
    if (!xpath || (typeof xpath == 'undefined') || xpath == null) {
        return nodes
    }
    if (!xmlDom) {
        xmlDom = document
    }
    if (typeof xmlDom.evaluate != 'undefined') {
        var result = xmlDom.evaluate(xpath, xmlDom, null, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null);
        if (result != null) {
            var node = null;
            while ((node = result.iterateNext()) != null) {
                nodes.push(node)
            }
        }
    }
    return nodes
}
function BJA_nodeDocumentForXPath(xpath) {
    return BJA_nodeForXPath(false, xpath)
}
function BJA_nodesDocumentForXPath(xpath) {
    return BJA_nodesForXPath(false, xpath)
}
function BJA_indexOfArray(array, val) {
    for (var i = 0; i < array.length; i++) {
        if (array[i] == val) {
            return i
        }
    }
    return - 1
}
function BJA_removeObjectInArray(array, val) {
    var index = BJA_indexOfArray(array, val);
    if (index > -1) {
        array.splice(index, 1)
    }
}
function BJA_isJSON(str) {
    if (str && (typeof str == 'string')) {
        try {
            if (typeof JSON.parse(str) == "object") {
                return true
            }
        } catch(e) {}
    }
    return false
}
function BJA_getJSON(str) {
    if (str && (typeof str == 'string')) {
        try {
            var ret = JSON.parse(str);
            if (typeof ret == "object") {
                return ret
            }
        } catch(e) {}
    } else if (typeof str == "object") {
        return str
    }
    return false
}
function BJA_objToJSONString(jsObj) {
    var ret = null;
    try {
        ret = JSON.stringify(jsObj)
    } catch(e) {}
    return ret
}
function BJA_isArray(obj) {
    var ret = false;
    try {
        if (Array.isArray(obj)) {
            ret = true
        } else {}
    } catch(e) {}
    return ret
}
function BJA_isfunction(FunName) {
    var ret = false;
    try {
        if (typeof FunName === "function") {
            ret = true
        } else {}
    } catch(e) {}
    return ret
}
function BJA_isString(str) {
    var ret = false;
    try {
        if (typeof str === 'string') {
            ret = true
        } else {}
    } catch(e) {}
    return ret
}
function BJA_StringLength(str) {
    var len = 0;
    for (var i = 0; i < str.length; i++) {
        var c = str.charCodeAt(i);
        if ((c >= 0x0001 && c <= 0x007e) || (0xff60 <= c && c <= 0xff9f)) {
            len++
        } else {
            len += 2
        }
    }
    return len
}
function BJA_invalidString(str) {
    if (!str || str == null || !BJA_isString(str)) {
        return true
    }
    return BJA_StringLength(str) == 0
}
function BJA_nonullString(str) {
    return ! BJA_invalidString(str)
}
function BJA_isObject(obj) {
    var ret = false;
    try {
        if (typeof obj === "object") {
            ret = true
        } else {}
    } catch(e) {}
    return ret
}
function BJA_isOnlyObject(val) {
    return val != null && typeof val === 'object' && Array.isArray(val) === false
}
function BJA_convertToSting(v, callback) {
    var rt = null;
    if (v === undefined) {} else if (typeof v === 'string') {
        rt = v
    } else if (typeof v == "object") {
        if (callback) {
            rt = callback(v)
        }
    } else if (BJA_isArray(v)) {
        if (callback) {
            rt = callback(v)
        }
    } else {
        rt = v + "";
        if (rt.length == 0) {
            rt = null
        }
    }
    return rt
}
function BJA_ToSting(v) {
    var rt = null;
    try {
        rt = BJA_convertToSting(v, false)
    } catch(e) {
        rt = null
    }
    return rt
}
function BJA_parseInt(text) {
    var num = -1;
    var str = "";
    if (text != null) {
        try {
            str = "" + text
        } catch(e) {}
        var tnum = false;
        try {
            tnum = str.replace(/[^0-9]/ig, "")
        } catch(e) {
            tnum = false
        }
        try {
            if (tnum === false) {
                num = parseInt(str)
            } else {
                if (tnum != "") {
                    num = parseInt(tnum)
                }
            }
            if (num == 'NaN') {
                num = -1
            }
        } catch(e) {
            num = -1
        }
    }
    return num
}
function BJA_string_trim(str) {
    var ret = null;
    if (str != null) {
        try {
            ret = str.replace(/(^\\s*)|(\\s*$)/g, "")
        } catch(e) {}
    }
    return ret
}
function BJA_string_trim_ctl(str) {
    var ret = null;
    if (str != null) {
        try {
            ret = str.replace(/(^[\\s\\n\\t]+|[\\s\\n\\t]+$)/g, "")
        } catch(e) {}
    }
    return ret
}
function BJA_string_trim_all(str) {
    var result = BJA_string_trim(str);
    if (result != null) {
        try {
            result = result.replace(/\\s/g, "")
        } catch(e) {}
    }
    return result
}
function BJA_ArrayContains(array, obj) {
    var i = array.length;
    while (i--) {
        if (array[i] === obj) {
            return true
        }
    }
    return false
}
function BJA_getImages() {
    var objs = document.getElementsByTagName("img");
    var imgSrcList = new Array();
    var j = 0;
    for (var i = 0; i < objs.length; i++) {
        var srcStr = objs[i].src;
        if (srcStr) {
            imgSrcList[j] = srcStr;
            j++
        }
    };
    return imgSrcList
}
function BJA_getImageCount() {
    var objs = document.getElementsByTagName("img");
    var j = 0;
    for (var i = 0; i < objs.length; i++) {
        if (objs[i].src) {
            j++
        }
    };
    return j
}
function BJA_stringByMatch(string, regex, capture) {
    var rc = null;
    try {
        var matches = string.match(regex);
        if ((matches != null) && (matches.length > capture)) {
            rc = matches[capture]
        }
    } catch(e) {
        rc = null
    }
    return rc
}
function BJA_isMatchByString(string, regex) {
    var rc = 0;
    try {
        if (string != null && string != "") {
            var matches = string.match(regex);
            if ((matches != null) && (matches.length > 0)) {
                rc = 1
            }
        }
    } catch(e) {
        rc = 0
    }
    return rc
}
function BJA_getImagesLinksString() {
    var objs = document.getElementsByTagName('img');
    var imgScr = "";
    for (var i = 0; i < objs.length; i++) {
        imgScr = imgScr + objs[i].src + '+'
    };
    return imgScr
}
function BJA_isImageVisible(element) {
    return BJA_isVisible(element)
}
function BJA_isVisible(element) {
    return (element.style.display != "none" && element.style.visibility != "hidden")
}
function BJA_getWindowHeight() {
    var windowHeight = 0;
    var isCSS1Compat = ((document.compatMode || "") === "CSS1Compat");
    if (isCSS1Compat) {
        windowHeight = document.documentElement.clientHeight
    } else {
        windowHeight = document.body.clientHeight
    }
    return windowHeight
}
function BJA_getWindowWidth() {
    var w = document.documentElement.clientWidth || window.innerWidth || document.body.clientWidth;
    return w
}
function BJA_isVisibleInWindowTop(element) {
    return element && (element.getBoundingClientRect().top < 0)
}
function BJA_isVisibleInWindowBottom(element) {
    var wh = BJA_getWindowHeight();
    return element && (element.getBoundingClientRect().top < wh)
}
function BJA_isVisibleInWindow(element) {
    var wh = BJA_getWindowHeight();
    return element && element && (element.getBoundingClientRect().top >= 0) && (element.getBoundingClientRect().top < wh)
}
function BJA_getHTMLElementsAtPoint(x, y) {
    var tags = ",";
    var e = document.elementFromPoint(x, y);
    while (e) {
        if (e.tagName) {
            tags += e.tagName + ','
        }
        e = e.parentNode
    }
    return tags
}
function BJA_setCssClassdisplayNone(cssclass) {
    if (cssclass) {
        var nv = "" + cssclass;
        var list = document.documentElement.getElementsByClassName(nv);
        var i = 0;
        for (i = 0; i < list.length; i++) {
            list[i].style.display = 'none'
        }
    }
}
function BJA_hideElement(elem) {
    var ret = false;
    if (!elem) {
        return ret
    }
    try {
        elem.style.display = 'none';
        ret = true
    } catch(e) {
        ret = false
    }
    return ret
}
function BJA_visiableElement(elem) {
    var ret = false;
    if (!elem) {
        return ret
    }
    try {
        elem.classList.remove("hidden");
        elem.style.display = 'block';
        ret = true
    } catch(e) {
        ret = false
    }
    return ret
}
function BJA_removeNode(node) {
    var ret = false;
    try {
        if (node) {
            var pnode = node.parentNode;
            if (pnode) {
                pnode.removeChild(node)
            }
        }
        ret = true
    } catch(e) {
        ret = 0
    }
    return ret
}
function BJA_isContainsClassOfElement(e, cname) {
    var b = 0;
    try {
        b = (e && cname && (e.classList.contains(cname) == true))
    } catch(e) {}
    return b
}
function BJA_isContainsClassItemOfElement(e, cname) {
    var b = 0;
    try {
        if (e && cname && e.classList) {
            var lowercname = cname.toLowerCase();
            for (var i = 0; i < e.classList.length; i++) {
                var classItem = e.classList.item(i);
                if (classItem) {
                    classItem = classItem.toLowerCase()
                }
                if (classItem.indexOf(lowercname) > 0) {
                    b = 1;
                    break
                }
            }
        }
    } catch(e) {}
    return b
}
function BJA_isMatchClassItemOfElement(e, regex) {
    var b = 0;
    try {
        if (e && regex && e.classList) {
            for (var i = 0; i < e.classList.length; i++) {
                var classItem = e.classList.item(i);
                if (BJA_isMatchByString(classItem, regex)) {
                    b = 1;
                    break
                }
            }
        }
    } catch(e) {}
    return b
}
function BJA_elementClassNameEqual(e, cname) {
    var b = 0;
    try {
        b = (e && cname && (e.className == cname))
    } catch(e) {}
    return b
}
function BJA_isContainsClassListOfElement(e, cnamelist, allFlag) {
    var b = 0;
    try {
        var ls = cnamelist.length;
        for (var i = 0; i < ls; i++) {
            var f = BJA_isContainsClassOfElement(cnamelist[i]);
            if (allFlag) {
                if (!f) {
                    break
                } else if (i + 1 == ls) {
                    b = 1;
                    break
                }
            } else if (f) {
                b = 1;
                break
            }
        }
        if (allFlag) {}
    } catch(e) {}
    return b
}
function BJA_getElementsByTagName(nodeName) {
    var rets = [];
    if (nodeName && BJA_isString(nodeName)) {
        try {
            rets = document.getElementsByTagName(nodeName)
        } catch(e) {
            rets = []
        }
    }
    return rets
}
function BJA_findAllFrameElements(name, fid) {
    var rets = new Array();
    if (fid) {
        var tt = document.getElementById(name);
        if (tt) {
            rets.push(tt)
        }
    } else {
        var as = BJA_getElementsByTagName(name);
        if (as.length > 0) {
            for (var i = 0; i < as.length; i++) {
                rets.push(as[i])
            }
        }
    }
    var c = document.querySelectorAll("iframe");
    if (c == null) {
        c = []
    }
    for (b = 0; b < c.length; ++b) {
        var iframe = c[b];
        var doc = false;
        try {
            doc = iframe.contentWindow.document
        } catch(e) {
            wbsdk_console('get iframe content window document error:' + e)
        }
        if (!doc) {
            try {
                doc = iframe.contentDocument
            } catch(e) {}
        }
        if (doc) {
            try {
                if (fid) {
                    var tt = doc.getElementById(name);
                    if (tt) {
                        rets.push(tt)
                    }
                } else {
                    var as = doc.getElementsByTagName(name);
                    if (as.length > 0) {
                        for (var i = 0; i < as.length; i++) {
                            rets.push(as[i])
                        }
                    }
                }
            } catch(e) {
                wbsdk_console('get iframe content window document getElementById error:' + e)
            }
        }
    }
    return rets
}
function BJA_AddToHeadStyle(cssStr, idStr) {
    rc = false;
    try {
        var cssnode = document.querySelector("style#" + idStr);
        if (cssnode != null && (cssnode.textContent != cssStr)) {
            BJA_removeNode(cssnode);
            cssnode = null
        }
        if (cssnode == null) {
            var header = BJA_DocumentHead();
            if (header) {
                try {
                    var s = document.createElement('style');
                    s.setAttribute('type', 'text/css');
                    s.setAttribute('id', idStr);
                    s.innerHTML = "";
                    s.appendChild(document.createTextNode(cssStr));
                    header.appendChild(s);
                    rc = true
                } catch(e) {}
            }
        } else {
            rc = true
        }
    } catch(e) {}
    return rc
}
function BJA_run_throttle(func, wait, mustRun) {
    var timeout;
    var startTime = new Date();
    return function() {
        var context = this;
        var args = arguments;
        var curTime = new Date();
        clearTimeout(timeout);
        if (curTime - startTime >= mustRun) {
            func.apply(context, args);
            startTime = curTime;
        } else {
            timeout = setTimeout(func, wait);
        }
    };
}
function BJA_addElementEventWithThrottle(element, event, realFunc, wait, mustRun) {
    element.addEventListener(event, BJA_run_throttle(function() {
        if (realFunc) {
            realFunc(element);
        }
    },
        wait, mustRun));
}
function BJA_run_debounce(func, wait, immediate) {
    var timeout;
    return function() {
        var context = this;
        var args = arguments;
        var later = function() {
            timeout = null;
            if (!immediate) func.apply(context, args);
        };
        var callNow = immediate && !timeout;
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
        if (callNow) func.apply(context, args);
    };
}
function BJA_addElementEventWithDebounce(element, event, realFunc, wait, immediate) {
    element.addEventListener(event, BJA_run_debounce(function() {
        if (realFunc) {
            realFunc(element);
        }
    },
        wait, immediate));
}
function BJA_MutationNodeChildList(targetNode, changedFn) {
    try {
        const config = {
            childList: true,
        };
        var rx = BJA_run_debounce(function() {
            try {
                if (changedFn) {
                    changedFn();
                }
                wbsdk_console('A child node has been added or removed.');
            } catch(e) {}
        },
            1000, false);

        const callback = function(mutationsList, observer) {
            for (var mutation of mutationsList) {
                if (mutation.type === 'childList') {
                    rx();
                }
            }
        };
        const observer = new MutationObserver(callback);
        observer.observe(targetNode, config);
    } catch(e) {
        wbsdk_console('A child node chang mutation failed:' + e);
    }
}

function BJA_MutationNodeAttributes(targetNode, changedFn) {
    try {
        const config = {
            attributes: true,
        };
        var rax = BJA_run_debounce(function() {
            try {
                if (changedFn) {
                    changedFn();
                }
                wbsdk_console('A child attributes has been added or removed.');
            } catch(e) {}
        },
            1000, false);

        const callback = function(mutationsList, observer) {
            for (let mutation of mutationsList) {
                if (mutation.type === 'attributes') {
                    rax();
                }
            }
        };
        const observer = new MutationObserver(callback);
        observer.observe(targetNode, config);
    } catch(e) {}
}
function BJA_getTheme() {
    if (!window) {
        return 'unkown'
    }
    const darkThemeMq = window.matchMedia("(prefers-color-scheme: dark)");
    if (darkThemeMq.matches) {
        return "dark"
    } else {
        return "light"
    }
}

function BJA_getStringFromB64String(s) {
    return atob(s);
}

function BJA_getB64StringFromString(s) {
    return btoa(s);
}

function BJA_UpdateThemeCallback() {
    wbsdk_console('--当前主题--:' + BJA_getTheme());
}

function BJA_addThemeChangListener(callback) {
    var r = false;
    if (!window) {
        wbsdk_console('------------监听theme失败 window is null----------------');
        return r
    }
    try {
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', callback != null ? callback: BJA_UpdateThemeCallback);
        window.matchMedia('(prefers-color-scheme: light)').addEventListener('change', callback != null ? callback: BJA_UpdateThemeCallback);
        r = true;
        wbsdk_console('------------监听theme成功----------------');
    } catch(e) {

    }
    return r;
}

function webinterfaceGetLoginUserInfo(){
    var ret = new Object;
    var userUrl =null;
    var username =null;
    var pcSels = [
        "div[id='hd'] div[id='um'] div.avt a[href*='space-uid-']",
    ];
    var mbSels = [
        "section#avatar_pop div.ava_user a[href*='uid=']",
    ];
    var atextfilters=[];
    var aclassfilters =[];
    var sels;
    var url =BJA_GetURL ();
    ret.src = url?url:'';
    var iconurl = null;

    if((url!=null && (url.indexOf('mobile=2')>-1))){
        sels = mbSels.concat(pcSels);
    }else{
        sels = pcSels.concat(mbSels);
    }
    for (var i =0; i< sels.length; i++){
        var anodes = document.querySelectorAll(sels[i]);
        if(anodes){
            var len = anodes.length;
            for(var j = len -1; j>=0; j--){
                var anode =  anodes[j];
                var clsVall= BJA_ele_getStringAttribute(anode,"class");
                var clstext= anode.text;
                if(clstext!=null){
                    clstext= clstext.trim();
                }
                if(  ((clstext ==null ) || (clstext!=null) &&( atextfilters.indexOf(clstext)<0) )
                    &&
                    ((clsVall==null) ||  ((clsVall!=null) && (aclassfilters.indexOf(clsVall)<0)))){
                    var slink= BJA_ele_getStringAttribute(anode,"href");
                    if(slink!=null){
                        userUrl= BJA_getEntireUrl(slink,url);
                        if(userUrl!=null){
                            username = clstext;
                            var img = anode.querySelector("img.user_avatar");
                            if(img){
                                var imgSrc=BJA_ele_getStringAttribute(img,"src");
                                if(imgSrc!=null){
                                    iconurl= (url!=null)? BJA_getEntireUrl(imgSrc,url):imgSrc;
                                    if(iconurl.toLowerCase().indexOf('http')!=0){
                                        iconurl =null;
                                    }
                                }
                            }
                            break;
                        }else{
                            userUrl=null;
                        }
                    }
                }
            }
            if(userUrl!=null){
                break;
            }
        }
    }
    ret.url = userUrl?userUrl:'';
    ret.name = username?username:'';
    ret.icon = iconurl?iconurl:'';
    return BJA_objToJSONString(ret);
}


function webinterfaceFilterChanged(jsonParams){
    try {
        if (!jsonParams) {
            return;
        }
        var blacklist = BJA_getJSON(jsonParams);
        if( (!blacklist) ||( blacklist.length<=0)){
            try {
                if (window.jszGVars.blacklist.length > 0) {
                    blacklist = window.jszGVars.blacklist;
                }
            }catch(e){

            }
            if( (!blacklist) ||( blacklist.length<=0)){
                return;
            }

        }else{
            try {
                window.jszGVars.blacklist =blacklist;
            }catch(e){}
        }
        var filterCount = 0;
        var filtedCount = 0;
        var filterFailedCount = 0;
        var delFilterCount = 0;
        var url =BJA_GetURL ();
        var shouldCheck = true;
        try{
            if((url!=null) && !((url.indexOf('chiphell.com')>-1))){
                shouldCheck =  false;
            }
        }catch(e){

        }
        if(shouldCheck && ( blacklist.length>0)){
            var cssList = [];
            var type = 0;
            if((url!=null && (url.indexOf('mobile=2')>-1))){
                type =1;
            }else{
                type=2;
            }
            //ccs1 | css2 css1为要屏蔽的块，css2为查找过滤用户
            cssList.push(".plcnotfirst|.ausize");
            cssList.push("div#comment ul.cl li |div.at1 h3 a[href*='mod=space']");
            cssList.push("[id^='thread']|a[c='1']");
            cssList.push("div#postlist [id^='post_']|a.xw1");
            for(var vsi =0; vsi< cssList.length; vsi++){
                var qsaList =  cssList[vsi].split('|');
                var firstCss =qsaList[0] ;
                var secondCss = qsaList[1];
                var aquerycount =1;
                if(qsaList.length>2){
                    aquerycount=parseInt(qsaList[2]);
                }
                var list =[];
                try{
                    list = document.querySelectorAll(firstCss);
                }catch(e){
                }

                var i= list.length-1;
                while(i>=0){
                    var node = list[i];
                    var fd = false;
                    try{
                        var alist=[];
                        if(aquerycount==1){
                            try{
                                var an = node.querySelector(secondCss);
                                if(an){
                                    alist.push(an);
                                }
                            }catch(e){
                            }
                        }else{
                            try{
                                alist = node.querySelectorAll(secondCss);
                            }catch(e){

                            }
                        }
                        if(alist){
                            for(var j =0; j< alist.length; j++){
                                var anode= alist[j];
                                var user= anode.text.trim();
                                if(blacklist.indexOf(user)>-1){
                                    fd = true;
                                    break;
                                }
                            }
                        }

                        if(fd){
                            if(BJA_isVisible(node)){
                                if(BJA_hideElement(node)){
                                    BJA_ele_setIntAttribute(node,'_zjsfilter',1);
                                    filterCount++;
                                }else{
                                    filterFailedCount++;
                                }
                            }else{
                                filtedCount++;
                            }
                        }
                        else{
                            var flg= BJA_ele_getIntAttribute(node,'_zjsfilter');
                            if(flg !=null && (flg==1)){
                                BJA_ele_setIntAttribute(node,'_zjsfilter',0);
                                node.style.display = "block";
                                delFilterCount++;
                            }
                        }
                    } catch(e) {}

                    i--;
                }
            }
        }
        wbsdk_console('过滤列表：' +blacklist.join('|') +  '; 执行标记:' +(shouldCheck?1:0) + ' 次数：1'+'; 屏蔽:'+filterCount +'; 之前屏蔽：'+filtedCount +'; 屏蔽失败：'+filterFailedCount+'; 去掉屏蔽:'+ delFilterCount);
    }catch(e){

    }
}

function BJA_jszFuncClickTapFavor(cs){
    var r =false;
    try{
        var node = document.querySelector(cs);
        if(node){
            node.addEventListener('click',function(event){

                try{
                    window.JsBridge.tapFavorite(r);
                }catch(e){

                }

            });
            r = true;
        }else{

        }
    }catch (e){

    }
    return r;
}

async function BJA_loadImage (params) {
    // 图片src 必传
    let src = params.src
    return new Promise((resolve, reject) => {
        let img = new Image()
        img.src = src
        try{
            img.crossOrigin = 'anonymous'
        }catch(e){
        }
        img.onload = () => {
            resolve(img)
        }
        img.onerror = reject
    })
}

function BJA_img2Base64 (image) {
    // 图片画到canvas
    const canvas = document.createElement('canvas');
    canvas.width = image.width;
    canvas.height = image.height;
    const context = canvas.getContext('2d');
    context.drawImage(image, 0, 0);
    return canvas.toDataURL('image/png', 1.0)
}

function BJA_base64ToBlob (base64Code) {
    let parts = base64Code.split(';base64,')
    let contentType = parts[0].split(':')[1]
    let raw = window.atob(parts[1])
    let rawLength = raw.length
    let uInt8Array = new Uint8Array(rawLength)
    for (let i = 0; i < rawLength; ++i) {
        uInt8Array[i] = raw.charCodeAt(i)
    }
    return new Blob([uInt8Array], {
        type: contentType
    })
}

function BJA_downloadFile(href, filename) {
    const link = document.createElement('a');
    link.href = href;
    link.download = filename;
    link.setAttribute('type', 'application/octet-stream');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
async function BJA_downloadImg1(imageUrl) {
    const image = await BJA_loadImage({src: imageUrl})
    let base64 = BJA_img2Base64(image)
    BJA_downloadFile(base64, 'file.png');
}
async function BJA_downloadImg2(imageUrl) {
    const image = await BJA_loadImage({src: imageUrl})
    let base64 = BJA_img2Base64(image)
    let blob = BJA_base64ToBlob(base64)
    // 下载图片
    BJA_downloadFile(URL.createObjectURL(blob), 'file.png');
}


function BJA_getNavInfoObject()
{
    var backInfo = new Object;
    try{
        var url =BJA_GetURL ();
        backInfo.src = url;
        var list =document.querySelectorAll("section.pop_board_nav a ");
        if (list.length ==0) {
            list =document.querySelectorAll("div.pop_board_nav a ");
        }
        if (list.length ==0) {
            list =document.querySelectorAll("div#pt div.z a ");
        }
        var last = list.length-1;
        var i = last;
        while(i>=0) {
            var anode = list[i];
            var title= anode.text.trim();
            if ((title.length > 0) &&(title != '回复') ) {
                var link = BJA_ele_getStringAttribute(anode,'href');
                if ( link =='index.php?mobile=2' ||
                    link =='forum.php?mobile=2' ||
                    (  (link.indexOf('forum.php') > -1)  && (i!=last)  ) ||
                    ( (link.indexOf('portal.php') > -1)  && (i!=last)  )
                )
                {
                    var forumUrl =  BJA_getEntireUrl(link,url);
                    if( (forumUrl!= url) && (forumUrl.toLowerCase().indexOf('http')==0)  ){
                        backInfo.title =title;
                        backInfo.url =forumUrl;
                        break;
                    }
                }
            }
            i--;
        }
    }catch(e){

    }
    return backInfo;
}

function BJA_getNavInfoString() {
    var backInfo =  BJA_getNavInfoObject();
    if (backInfo.src == window.jszGVars.src) {
        window.jszGVars.backNavObject = backInfo;
    }
    return  BJA_objToJSONString(window.jszGVars.backNavObject);
}



try{
    if(window != undefined){
        _bja_safeInitVars();
    }
}catch (ex) {

}

try{
    window.document.addEventListener('DOMContentLoaded', function() {
        _bja_safeInitVars();
        wbsdk_console('-------------------DOMContentLoaded ');
    });
}catch (ex) {
    wbsdk_console('-------------------add DOMContentLoaded error:'+ex+ '------------------');
}

