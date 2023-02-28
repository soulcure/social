if (window.__wxjs_environment == "miniprogram") {
  window.open = () => { };

  var query = {};
  var search = location.search.substr(1);
  search.split("&").forEach((e) => {
    var kv = e.split("=");
    query[kv[0]] = kv[1];
  });
  if (query.sign) {
    query.gender = parseInt(query.gender);
    query.presence_status = parseInt(query.presence_status);
    query.nickname = decodeURIComponent(query.nickname);

    setCookie('token', query.sign, 30);
    localStorage.setItem("flutter.login_time", Date.now());
    localStorage.setItem("flutter.UserInfo_2", JSON.stringify(JSON.stringify(query)));
  }
}

function setCookie(cname, cvalue, exdays) {
  var d = new Date();
  d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));
  var expires = "expires=" + d.toGMTString();
  document.cookie = cname + "=" + cvalue + "; " + expires;
}

function cropImage(params) {
  let bytes = params[0]
  let scale = params[1]
  let offset = params[2]
  return bytes
}

function initNotification() {
  Notification.requestPermission();
}

function pushNotification(title, content) {
  var notification = new Notification(title, { body: content });
}

function gzip(bytes) {
    var binData = new Uint8Array(bytes);
    return pako.inflate(binData,{to: 'string'});
}