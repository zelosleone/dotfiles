function FindProxyForURL(url, host) {
  if (shExpMatch(url, "*://crunchyroll.com/auth/v1/token*")) {
    return "SOCKS5 cr-unblocker.us.to:1080; DIRECT";
  }
  return "DIRECT";
}
