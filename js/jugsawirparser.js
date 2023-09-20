// json view
!function(e,n){"object"==typeof exports&&"object"==typeof module?module.exports=n():"function"==typeof define&&define.amd?define([],n):"object"==typeof exports?exports.jsonview=n():e.jsonview=n()}(self,(function(){return(()=>{"use strict";var e={767:(e,n,t)=>{t.d(n,{Z:()=>s});var r=t(81),o=t.n(r),i=t(645),a=t.n(i)()(o());a.push([e.id,'.json-container{font-family:"Open Sans";font-size:16px;background-color:#fff;color:gray;box-sizing:border-box}.json-container .line{margin:4px 0;display:flex;justify-content:flex-start}.json-container .caret-icon{width:18px;text-align:center;cursor:pointer}.json-container .empty-icon{width:18px}.json-container .json-type{margin-right:4px;margin-left:4px}.json-container .json-key{color:#444;margin-right:4px;margin-left:4px}.json-container .json-index{margin-right:4px;margin-left:4px}.json-container .json-value{margin-left:8px}.json-container .json-number{color:#f9ae58}.json-container .json-boolean{color:#ec5f66}.json-container .json-string{color:#86b25c}.json-container .json-size{margin-right:4px;margin-left:4px}.json-container .hidden{display:none}.json-container .fas{display:inline-block;border-style:solid;width:0;height:0}.json-container .fa-caret-down{border-width:6px 5px 0 5px;border-color:gray transparent}.json-container .fa-caret-right{border-width:5px 0 5px 6px;border-color:transparent transparent transparent gray}',""]);const s=a},645:e=>{e.exports=function(e){var n=[];return n.toString=function(){return this.map((function(n){var t="",r=void 0!==n[5];return n[4]&&(t+="@supports (".concat(n[4],") {")),n[2]&&(t+="@media ".concat(n[2]," {")),r&&(t+="@layer".concat(n[5].length>0?" ".concat(n[5]):""," {")),t+=e(n),r&&(t+="}"),n[2]&&(t+="}"),n[4]&&(t+="}"),t})).join("")},n.i=function(e,t,r,o,i){"string"==typeof e&&(e=[[null,e,void 0]]);var a={};if(r)for(var s=0;s<this.length;s++){var c=this[s][0];null!=c&&(a[c]=!0)}for(var l=0;l<e.length;l++){var d=[].concat(e[l]);r&&a[d[0]]||(void 0!==i&&(void 0===d[5]||(d[1]="@layer".concat(d[5].length>0?" ".concat(d[5]):""," {").concat(d[1],"}")),d[5]=i),t&&(d[2]?(d[1]="@media ".concat(d[2]," {").concat(d[1],"}"),d[2]=t):d[2]=t),o&&(d[4]?(d[1]="@supports (".concat(d[4],") {").concat(d[1],"}"),d[4]=o):d[4]="".concat(o)),n.push(d))}},n}},81:e=>{e.exports=function(e){return e[1]}},379:e=>{var n=[];function t(e){for(var t=-1,r=0;r<n.length;r++)if(n[r].identifier===e){t=r;break}return t}function r(e,r){for(var i={},a=[],s=0;s<e.length;s++){var c=e[s],l=r.base?c[0]+r.base:c[0],d=i[l]||0,p="".concat(l," ").concat(d);i[l]=d+1;var u=t(p),f={css:c[1],media:c[2],sourceMap:c[3],supports:c[4],layer:c[5]};if(-1!==u)n[u].references++,n[u].updater(f);else{var v=o(f,r);r.byIndex=s,n.splice(s,0,{identifier:p,updater:v,references:1})}a.push(p)}return a}function o(e,n){var t=n.domAPI(n);return t.update(e),function(n){if(n){if(n.css===e.css&&n.media===e.media&&n.sourceMap===e.sourceMap&&n.supports===e.supports&&n.layer===e.layer)return;t.update(e=n)}else t.remove()}}e.exports=function(e,o){var i=r(e=e||[],o=o||{});return function(e){e=e||[];for(var a=0;a<i.length;a++){var s=t(i[a]);n[s].references--}for(var c=r(e,o),l=0;l<i.length;l++){var d=t(i[l]);0===n[d].references&&(n[d].updater(),n.splice(d,1))}i=c}}},569:e=>{var n={};e.exports=function(e,t){var r=function(e){if(void 0===n[e]){var t=document.querySelector(e);if(window.HTMLIFrameElement&&t instanceof window.HTMLIFrameElement)try{t=t.contentDocument.head}catch(e){t=null}n[e]=t}return n[e]}(e);if(!r)throw new Error("Couldn't find a style target. This probably means that the value for the 'insert' parameter is invalid.");r.appendChild(t)}},216:e=>{e.exports=function(e){var n=document.createElement("style");return e.setAttributes(n,e.attributes),e.insert(n,e.options),n}},565:(e,n,t)=>{e.exports=function(e){var n=t.nc;n&&e.setAttribute("nonce",n)}},795:e=>{e.exports=function(e){var n=e.insertStyleElement(e);return{update:function(t){!function(e,n,t){var r="";t.supports&&(r+="@supports (".concat(t.supports,") {")),t.media&&(r+="@media ".concat(t.media," {"));var o=void 0!==t.layer;o&&(r+="@layer".concat(t.layer.length>0?" ".concat(t.layer):""," {")),r+=t.css,o&&(r+="}"),t.media&&(r+="}"),t.supports&&(r+="}");var i=t.sourceMap;i&&"undefined"!=typeof btoa&&(r+="\n/*# sourceMappingURL=data:application/json;base64,".concat(btoa(unescape(encodeURIComponent(JSON.stringify(i))))," */")),n.styleTagTransform(r,e,n.options)}(n,e,t)},remove:function(){!function(e){if(null===e.parentNode)return!1;e.parentNode.removeChild(e)}(n)}}}},589:e=>{e.exports=function(e,n){if(n.styleSheet)n.styleSheet.cssText=e;else{for(;n.firstChild;)n.removeChild(n.firstChild);n.appendChild(document.createTextNode(e))}}}},n={};function t(r){var o=n[r];if(void 0!==o)return o.exports;var i=n[r]={id:r,exports:{}};return e[r](i,i.exports,t),i.exports}t.n=e=>{var n=e&&e.__esModule?()=>e.default:()=>e;return t.d(n,{a:n}),n},t.d=(e,n)=>{for(var r in n)t.o(n,r)&&!t.o(e,r)&&Object.defineProperty(e,r,{enumerable:!0,get:n[r]})},t.o=(e,n)=>Object.prototype.hasOwnProperty.call(e,n),t.r=e=>{"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})};var r={};return(()=>{t.r(r),t.d(r,{collapse:()=>$,create:()=>O,default:()=>I,destroy:()=>z,expand:()=>P,render:()=>A,renderJSON:()=>N});var e=t(379),n=t.n(e),o=t(795),i=t.n(o),a=t(569),s=t.n(a),c=t(565),l=t.n(c),d=t(216),p=t.n(d),u=t(589),f=t.n(u),v=t(767),y={};function h(e){return Array.isArray(e)?"array":null===e?"null":typeof e}function m(e){return document.createElement(e)}y.styleTagTransform=f(),y.setAttributes=l(),y.insert=s().bind(null,"head"),y.domAPI=i(),y.insertStyleElement=p(),n()(v.Z,y),v.Z&&v.Z.locals&&v.Z.locals;const x="hidden",g="fa-caret-right",j="fa-caret-down";function b(e){e.children.forEach((e=>{e.el.classList.add(x),e.isExpanded&&b(e)}))}function E(e){e.children.forEach((e=>{e.el.classList.remove(x),e.isExpanded&&E(e)}))}function S(e){if(e.children.length>0){const n=e.el.querySelector(".fas");n&&n.classList.replace(g,j)}}function k(e){if(e.children.length>0){const n=e.el.querySelector(".fas");n&&n.classList.replace(j,g)}}function w(e){e.isExpanded?(e.isExpanded=!1,k(e),b(e)):(e.isExpanded=!0,S(e),E(e))}function L(e,n){n(e),e.children.length>0&&e.children.forEach((e=>{L(e,n)}))}function T(e={}){return{key:e.key||null,parent:e.parent||null,value:e.hasOwnProperty("value")?e.value:null,isExpanded:e.isExpanded||!1,type:e.type||null,children:e.children||[],el:e.el||null,depth:e.depth||0,dispose:null}}function M(e,n){if("object"==typeof e)for(let t in e){const r=T({value:e[t],key:t,depth:n.depth+1,type:h(e[t]),parent:n});n.children.push(r),M(e[t],r)}}function C(e){return"string"==typeof e?JSON.parse(e):e}function O(e){const n=C(e),t=T({value:n,key:h(n),type:h(n)});return M(n,t),t}function N(e,n){const t=C(e),r=createTree(t);return A(r,n),r}function A(e,n){const t=function(){const e=m("div");return e.className="json-container",e}();L(e,(function(e){e.el=function(e){let n=m("div");const t=e=>{const n=e.children.length;return"array"===e.type?`[${n}]`:"object"===e.type?`{${n}}`:null};if(e.children.length>0){n.innerHTML=function(e={}){const{key:n,size:t}=e;return`\n    <div class="line">\n      <div class="caret-icon"><i class="fas fa-caret-right"></i></div>\n      <div class="json-key">${n}</div>\n      <div class="json-size">${t}</div>\n    </div>\n  `}({key:e.key,size:t(e)});const r=n.querySelector(".caret-icon");e.dispose=function(e,n,t){return e.addEventListener(n,t),()=>e.removeEventListener(n,t)}(r,"click",(()=>w(e)))}else n.innerHTML=function(e={}){const{key:n,value:t,type:r}=e;return`\n    <div class="line">\n      <div class="empty-icon"></div>\n      <div class="json-key">${n}</div>\n      <div class="json-separator">:</div>\n      <div class="json-value json-${r}">${t}</div>\n    </div>\n  `}({key:e.key,value:e.value,type:typeof e.value});const r=n.children[0];return null!==e.parent&&r.classList.add(x),r.style="margin-left: "+18*e.depth+"px;",r}(e),t.appendChild(e.el)})),n.appendChild(t)}function P(e){L(e,(function(e){e.el.classList.remove(x),e.isExpanded=!0,S(e)}))}function $(e){L(e,(function(n){n.isExpanded=!1,n.depth>e.depth&&n.el.classList.add(x),k(n)}))}function z(e){var n;L(e,(e=>{e.dispose&&e.dispose()})),(n=e.el.parentNode).parentNode.removeChild(n)}const I={render:A,create:O,renderJSON:N,expand:P,collapse:$,traverse:L,destroy:z}})(),r})()}));

//  Jugsaw Extension
//===============================
// extract data from inputs
function raw2json(obj, demo_obj){
    if (demo_obj instanceof Array){
        return obj.map((v, i) => raw2json(v, i < demo_obj.length ? demo_obj[i] : demo_obj[0]));
    } else if (demo_obj instanceof Object){
        return {'fields':obj.map((v, i)=>raw2json(v, demo_obj.fields[i]))}
    } else {
        return obj;
    }
}

function uuid4() {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  );
}

// Request an application and return an object as Promise.
// Please use `render_app` for further processing.
function request_app_obj(endpoint, project, appname, version="latest") {
    const url = new URL(`v1/proj/${project}/app/${appname}/ver/${version}/func`, endpoint).href
    return fetch(url, {
        method: 'GET',
    })
}

// Launch a function call and return a job_id as string.
function call(endpoint, project, appname, fname, args, kwargs, maxtime=60, created_by="unspecified", version="lastest"){
    const context = this.context;
    const url = new URL(`v1/proj/${project}/app/${appname}/ver/${version}/func/${fname}`, endpoint).href
    const job_id = uuid4();
    const jobspec = {
        "id" : job_id,
        "created_at" : Date.now(),
        "created_by" : created_by,
        "maxtime" : maxtime,
        "fcall" : {
            "fname" : fname,
            "args" : args,
            "kwargs" : kwargs
        }
    };
    return fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            "ce-id":uuid4(), "ce-type":"any", "ce-source":"any",
            "ce-specversion":"1.0"
        },
        body: JSON.stringify(jobspec)
    })
}

// fetch and return the result (as a Promise)
function fetch_result(endpoint, job_id) {
    const url = new URL(`v1/job/${job_id}/result`, endpoint).href
    return fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body : JSON.stringify({"job_id" : job_id})
    })
}

function error_message(txt){
    const obj = create_textblock('p', JSON.parse(txt).error);
    obj.style.color = "red";
    return obj
}

function aslist(adt){
  return adt
}

// TODO: render like Pluto
// render a demo as an object
function render_demo(demo, typemap){
    const [fcall, result, meta] = demo.fields;
    const metamap = render_dict(meta);
    // positional arguments
    const newargs = fcall.args.fields.map((arg, i)=>(
        {"arg_name":`${i+1}`, "data": render_value(arg, typemap), "type":get_type(arg)}
    ))
    // keyword arguments
    const kws = aslist(typemap[fcall.kwargs.type].fields[1]);
    const newkwargs = fcall.kwargs.fields.map((arg, i)=>(
        {"arg_name":kws[i], "data": render_value(arg, typemap), "type":get_type(arg)}
    ))
    return {"args":newargs, "kwargs":newkwargs,
        "result":render_value(result, typemap),
        "docstring":metamap.docstring,
        "api_julia":"", "api_javascript":"",
        "api_python":"",
    };
}
// get type of an argument safely
function get_type(value){
    if (value === null){
        return "null"
    } else if (value instanceof Object){
        return value.type
    } else {
        return typeof(value)
    }
}
// render the value as a normal JSON object
function render_value(value, typemap){
    if (value instanceof Array){
        return value.map(v=>render_value(v, typemap))
    } else if (value instanceof Object){
        // add fieldnames
        const [typename, fieldnames, fieldtypes] = typemap[value.type].fields;
        return render_object(value.type, aslist(fieldnames), value.fields.map(v=>render_value(v, typemap)));
    } else {
        return value
    }
}
// render an object
function render_object(typename, fieldnames, fields){
    return {"type":typename, "fieldnames":fieldnames, "fields": fields}
}
// create type dictionary from two arrays
function render_dict(adt){
    const _pairs = aslist(adt.fields[0]);
    const result = {};
    _pairs.forEach(pair => result[pair.fields[0]] = pair.fields[1]);
    return result;
}

// source: https://stackoverflow.com/questions/8493195/how-can-i-parse-a-csv-string-with-javascript-which-contains-comma-in-data
function csvToArray(text) {
    let p = '', row = [''], ret = [row], i = 0, r = 0, s = !0, l;
    for (l of text) {
        if ('"' === l) {
            if (s && l === p) row[i] += l;
            s = !s;
        } else if (',' === l && s) l = row[++i] = '';
        else if ('\n' === l && s) {
            if ('\r' === p) row[i] = row[i].slice(0, -1);
            row = ret[++r] = [l = '']; i = 0;
        } else row[i] += l;
        p = l;
    }
    return ret;
};

function listfromstring(s){
    return s.match(/[^,\s?]+/g)
}

// check types
function isarraytype(typename){
    const [primary, params] = decompose_type(typename);
    return primary == 'JugsawIR.JArray'
}
function issimplearraytype(typename){
    const [primary, params] = decompose_type(typename);
    const T = params[0];
    return primary == 'JugsawIR.JArray' && (isstringtype(T) || isbooltype(T) || isfloattype(T) || isintegertype(T) || iscomplextype(T))
}
function decompose_type(typename){
    const re = /(^[a-zA-Z_][a-zA-Z_0-9\.]*!?)\{(.*)\}$/
    const res = typename.match(re)
    if (res !== null){
        return [res[1], listfromstring(res[2])]
    } else {
        return [typename, '']
    }
}

function isintegertype(typename){
    return typename == "Core.Int128" ||
        typename == "Core.Int64" ||
        typename == "Core.Int32" ||
        typename == "Core.Int16" ||
        typename == "Core.Int8" ||
        typename == "Core.UInt128" ||
        typename == "Core.UInt64" ||
        typename == "Core.UInt32" ||
        typename == "Core.UInt16" ||
        typename == "Core.UInt8"
}
function isfloattype(typename){
    return typename == "Core.Float64" ||
        typename == "Core.Float32" ||
        typename == "Core.Float16"
}
function iscomplextype(typename){
    return typename == "Base.Complex{Core.Float64}" ||
        typename == "Base.Complex{Core.Float32}" ||
        typename == "Base.Complex{Core.Float16}"
}
function isbooltype(typename){
    return typename == "Core.Bool"
}
function isstringtype(typename){
    return typename == "Core.String"
}

class ClientContext {
  constructor({endpoint = window.location.href,
      project = "unspecified",
      version = "1.0"}) {
    this.endpoint = endpoint;
    this.project = project;
    this.version = version;
    this.appname = "unspecified";
  }
}

class App {
  constructor(
    appname,
    function_list,
    context){
      this.appname = appname;
      this.function_list = function_list;
      this.context = context;
    }

  call(fname, args, kwargs, ferror=console.log) {
    for (var i=0; i< this.function_list.length; i++){
      const fi = this.function_list[i]
      if (fi.function_name == fname){
        const demo = fi.demo
        const newargs = demo.args.map((darg, i)=>raw2json(args[i], darg.data));
        const newkwargs = demo.kwargs.map((darg,i)=>raw2json(kwargs[i], darg.data));
        return call(context.endpoint, context.project, context.appname, fname,
            {"fields":newargs},
            {"fields":newkwargs}
          ).then(resp=>{
          if (resp.status != 200){
            // call error
            resp.json().then(x=>ferror(x.error));
          } else {
            // an object id is returned
            return resp.json().then(data=>{
              const job_id = data.job_id
              console.log("job id = ", job_id)
              return fetch_result(context.endpoint, job_id).then(resp => {
                if (resp.status == 200){
                    // fetch result with the object id
                    return resp.text().then(ir=>{
                        // the result is returned as a Jugsaw object.
                        const result = ir2adt(ir);
                        return result
                    })
                } else {
                    resp.json().then(x=>ferror(x.error));
                }
              })
            })
          }
        })
      }
    }
  }
}