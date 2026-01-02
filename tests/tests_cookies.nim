# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk
# Tests for cookie templates in mummy_utils

import std/[unittest, times, options, strutils]
import std/cookies
from webby import HttpHeaders, toBase
import src/mummy_utils

suite "Cookie Templates Tests":
  test "setCookie with basic key-value":
    var headers: HttpHeaders
    mummy_utils.setCookie("testKey", "testValue")

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "testKey=testValue" in cookieValue
    check "Secure" in cookieValue
    check "HttpOnly" in cookieValue

  test "setCookie with domain and path":
    var headers: HttpHeaders
    mummy_utils.setCookie("session", "abc123", domain = "example.com", path = "/api")

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "session=abc123" in cookieValue
    check "Domain=example.com" in cookieValue
    check "Path=/api" in cookieValue

  test "setCookie with string expires":
    var headers: HttpHeaders
    let expiresStr = "Wed, 21 Oct 2025 07:28:00 GMT"
    mummy_utils.setCookie("expires", "value", expires = expiresStr)

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "expires=value" in cookieValue
    check expiresStr in cookieValue

  test "setCookie with DateTime expires":
    var headers: HttpHeaders
    let expires = now().utc + 1.hours
    mummy_utils.setCookie("datetime", "value", expires)

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "datetime=value" in cookieValue
    check "Expires=" in cookieValue

  test "setCookie with Time expires":
    var headers: HttpHeaders
    let expires = getTime() + 2.hours
    mummy_utils.setCookie("time", "value", expires)

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "time=value" in cookieValue
    check "Expires=" in cookieValue

  test "setCookie with maxAge":
    var headers: HttpHeaders
    mummy_utils.setCookie("maxage", "value", maxAge = some(3600))

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "maxage=value" in cookieValue
    check "Max-Age=3600" in cookieValue

  test "setCookie with sameSite Strict":
    var headers: HttpHeaders
    mummy_utils.setCookie("samesite", "value", sameSite = SameSite.Strict)

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "samesite=value" in cookieValue
    check "SameSite=Strict" in cookieValue

  test "setCookie with sameSite Lax":
    var headers: HttpHeaders
    mummy_utils.setCookie("samesite", "value", sameSite = SameSite.Lax)

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "samesite=value" in cookieValue
    check "SameSite=Lax" in cookieValue

  test "setCookie with sameSite None":
    var headers: HttpHeaders
    mummy_utils.setCookie("samesite", "value", sameSite = SameSite.None)

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "samesite=value" in cookieValue
    check "SameSite=None" in cookieValue

  test "setCookie with secure=false":
    var headers: HttpHeaders
    mummy_utils.setCookie("insecure", "value", secure = false)

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "insecure=value" in cookieValue
    check "Secure" notin cookieValue

  test "setCookie with httpOnly=false":
    var headers: HttpHeaders
    mummy_utils.setCookie("nohttponly", "value", httpOnly = false)

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "nohttponly=value" in cookieValue
    check "HttpOnly" notin cookieValue

  test "setCookie with all parameters":
    var headers: HttpHeaders
    let expires = now().utc + 1.days
    mummy_utils.setCookie(
      "full", "complete",
      expires,
      domain = "test.com",
      path = "/secure",
      secure = true,
      httpOnly = true,
      maxAge = some(86400),
      sameSite = SameSite.Strict
    )

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "full=complete" in cookieValue
    check "Domain=test.com" in cookieValue
    check "Path=/secure" in cookieValue
    check "Secure" in cookieValue
    check "HttpOnly" in cookieValue
    check "Max-Age=86400" in cookieValue
    check "SameSite=Strict" in cookieValue

  test "setCookie overwrites previous cookie":
    var headers: HttpHeaders
    mummy_utils.setCookie("overwrite", "first")
    mummy_utils.setCookie("overwrite", "second")

    check headers.hasKey("Set-Cookie")
    let cookieValue = headers["Set-Cookie"]
    check "overwrite=second" in cookieValue
    check "overwrite=first" notin cookieValue

  test "addCookie allows multiple cookies - basic":
    var headers: HttpHeaders
    mummy_utils.addCookie("cookie1", "value1")
    mummy_utils.addCookie("cookie2", "value2")
    mummy_utils.addCookie("cookie3", "value3")

    check headers.hasKey("Set-Cookie")

    # Count Set-Cookie headers - should be 3 separate headers
    var setCookieCount = 0
    var cookie1Found = false
    var cookie2Found = false
    var cookie3Found = false

    for header in headers.toBase:
      if header[0] == "Set-Cookie":
        setCookieCount += 1
        if "cookie1=value1" in header[1]:
          cookie1Found = true
        if "cookie2=value2" in header[1]:
          cookie2Found = true
        if "cookie3=value3" in header[1]:
          cookie3Found = true

    check setCookieCount == 3
    check cookie1Found
    check cookie2Found
    check cookie3Found

  test "addCookie allows multiple cookies - many cookies":
    var headers: HttpHeaders
    # Add 10 cookies to test scalability
    for i in 1..10:
      addCookie("cookie" & $i, "value" & $i)

    check headers.hasKey("Set-Cookie")

    # Count Set-Cookie headers - should be 10 separate headers
    var setCookieCount = 0
    var foundCookies: array[1..10, bool]

    for header in headers.toBase:
      if header[0] == "Set-Cookie":
        setCookieCount += 1
        for i in 1..10:
          if "cookie" & $i & "=value" & $i in header[1]:
            foundCookies[i] = true

    check setCookieCount == 10
    for i in 1..10:
      check foundCookies[i]

  test "addCookie allows multiple cookies with different attributes":
    var headers: HttpHeaders
    mummy_utils.addCookie("session", "abc123", domain = "example.com", path = "/api")
    mummy_utils.addCookie("pref", "dark", maxAge = some(3600))
    mummy_utils.addCookie("lang", "en", sameSite = SameSite.Strict)
    mummy_utils.addCookie("token", "xyz789", secure = false, httpOnly = false)

    check headers.hasKey("Set-Cookie")

    # Count Set-Cookie headers - should be 4 separate headers
    var setCookieCount = 0
    var sessionFound = false
    var prefFound = false
    var langFound = false
    var tokenFound = false

    for header in headers.toBase:
      if header[0] == "Set-Cookie":
        setCookieCount += 1
        let cookieValue = header[1]
        if "session=abc123" in cookieValue and "Domain=example.com" in cookieValue and "Path=/api" in cookieValue:
          sessionFound = true
        if "pref=dark" in cookieValue and "Max-Age=3600" in cookieValue:
          prefFound = true
        if "lang=en" in cookieValue and "SameSite=Strict" in cookieValue:
          langFound = true
        if "token=xyz789" in cookieValue and "Secure" notin cookieValue and "HttpOnly" notin cookieValue:
          tokenFound = true

    check setCookieCount == 4
    check sessionFound
    check prefFound
    check langFound
    check tokenFound

  test "addCookie allows multiple cookies with DateTime expires":
    var headers: HttpHeaders
    let expires1 = now().utc + 1.hours
    let expires2 = now().utc + 2.hours
    let expires3 = now().utc + 3.hours

    mummy_utils.addCookie("cookie1", "value1", expires1)
    mummy_utils.addCookie("cookie2", "value2", expires2)
    mummy_utils.addCookie("cookie3", "value3", expires3)

    check headers.hasKey("Set-Cookie")

    # Count Set-Cookie headers - should be 3 separate headers
    var setCookieCount = 0
    var cookie1Found = false
    var cookie2Found = false
    var cookie3Found = false

    for header in headers.toBase:
      if header[0] == "Set-Cookie":
        setCookieCount += 1
        let cookieValue = header[1]
        if "cookie1=value1" in cookieValue and "Expires=" in cookieValue:
          cookie1Found = true
        if "cookie2=value2" in cookieValue and "Expires=" in cookieValue:
          cookie2Found = true
        if "cookie3=value3" in cookieValue and "Expires=" in cookieValue:
          cookie3Found = true

    check setCookieCount == 3
    check cookie1Found
    check cookie2Found
    check cookie3Found

  test "addCookie allows multiple cookies - each in separate header":
    var headers: HttpHeaders
    mummy_utils.addCookie("a", "1")
    mummy_utils.addCookie("b", "2")
    mummy_utils.addCookie("c", "3")

    check headers.hasKey("Set-Cookie")

    # Verify each cookie is in its own header (not concatenated)
    var headersWithA = 0
    var headersWithB = 0
    var headersWithC = 0

    for header in headers.toBase:
      if header[0] == "Set-Cookie":
        let cookieValue = header[1]
        # Each header should contain exactly one cookie name
        if "a=1" in cookieValue:
          headersWithA += 1
          check "b=2" notin cookieValue
          check "c=3" notin cookieValue
        if "b=2" in cookieValue:
          headersWithB += 1
          check "a=1" notin cookieValue
          check "c=3" notin cookieValue
        if "c=3" in cookieValue:
          headersWithC += 1
          check "a=1" notin cookieValue
          check "b=2" notin cookieValue

    check headersWithA == 1
    check headersWithB == 1
    check headersWithC == 1

