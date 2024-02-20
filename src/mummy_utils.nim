# Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

import
  mummy,
  mummy/routers,
  mummy/multipart

import
  std/[
    cookies,
    json,
    mimetypes,
    strtabs,
    strutils,
    times
  ]

# Set cookies (get string) and samsite enum
export cookies.SameSite

# Access the `.params` with hasKey and pairs (loop)
export strtabs.hasKey, strtabs.pairs

# Exclude HttpHeaders since mummy exports webby's HttpHeaders
import std/httpcore except HttpHeaders
export httpcore except HttpHeaders

# Import query decoder, and `[]` for HttpHeaders
from webby import decodeQueryComponent, `[]`
export `[]`, HttpHeaders


type
  ContentType* = enum
    Json = "application/json"
    Text = "text/plain"
    Html = "text/html; charset=utf-8"


#
# Param generator
#
proc paramGeneratorValue*(request: Request, s: string): string =
  ## Find and return single param from request.
  ##
  ## Starts in:
  ## - URL path
  ## - URL query
  ## - body data.

  # 1. Path
  result = request.pathParams[s]
  if result != "":
    return result

  # 2. Query
  result = request.queryParams[s]
  if result != "":
    return result

  # 3. Body
  if "x-www-form-urlencoded" in request.headers["Content-Type"].toLowerAscii():
    for pairStr in request.body.split('&'):
      let
        pair = pairStr.split('=', 1)
        kv =
          if pair.len == 2:
            (decodeQueryComponent(pair[0]), decodeQueryComponent(pair[1]))
          else:
            (decodeQueryComponent(pair[0]), "")

      if kv[0] == s:
        return kv[1]



proc paramGenerator*(request: Request): StringTableRef =
  ## Generate params from request.
  ##
  ## Generates all params available in the request.
  ## Starts in:
  ## - body data
  ## - URI query
  ## - URI path

  result = newStringTable()

  # Body
  if "x-www-form-urlencoded" in request.headers["Content-Type"].toLowerAscii():
    for pairStr in request.body.split('&'):
      let
        pair = pairStr.split('=', 1)
        kv =
          if pair.len == 2:
            (decodeQueryComponent(pair[0]), decodeQueryComponent(pair[1]))
          else:
            (decodeQueryComponent(pair[0]), "")

      result[kv[0]] = kv[1]

  # Query
  for p in request.queryParams:
    result[p[0]] = p[1]

  # Path
  for p in request.pathParams:
    result[p[0]] = p[1]


#
# Request fields
#
proc body*(request: Request): string =
  ## Get body of request.
  return request.body


proc host*(request: Request): string =
  ## Get host of request.
  return request.headers["Host"]


proc ip*(request: Request): string =
  ## Get IP of request.
  result = request.headers["X-Forwarded-For"]
  if result == "":
    result = request.remoteAddress
  return result


proc path*(request: Request): string =
  ## Get path of request.
  if "?" notin request.uri:
    return request.uri
  return request.uri.split("?")[0]


proc query*(request: Request): string =
  ## Get query of request.
  if "?" notin request.uri:
    return ""
  return request.uri.split("?")[1]


proc reqMethod*(request: Request): HttpMethod =
  ## Get method of request.
  case request.httpMethod
  of "GET":
    return HttpGet
  of "POST":
    return HttpPost
  of "PUT":
    return HttpPut
  of "DELETE":
    return HttpDelete
  of "HEAD":
    return HttpHead
  of "TRACE":
    return HttpTrace
  of "OPTIONS":
    return HttpOptions
  of "CONNECT":
    return HttpConnect
  of "PATCH":
    return HttpPatch
  else:
    return HttpGet


proc multipart*(request: Request): seq[MultipartEntry] =
  ## Get multipart.
  try:
    request.decodeMultipart()
  except:
    @[]


proc secure*(request: Request): bool =
  ## Check if request is secure.
  case request.headers["X-Forwarded-Proto"]
  of "https":
    return true
  else:
    return false


#
# Headers
#
proc hasKey*(headers: HttpHeaders, key: string): bool =
  return headers.contains(key)


template setHeader*(field, value: string) =
  ## Set header of response.
  headers[field] = value



#
# Cookies
#
proc cookies*(request: Request, cookie: string): string =
  ## Get cookies of request.
  return parseCookies(request.headers["Cookie"]).getOrDefault(cookie, "")


proc cookies*(request: Request): StringTableRef =
  ## Get cookies of request.
  return parseCookies(request.headers["Cookie"])


template setCookie*(
    key, value: string,
    domain = "", path = "", expires = "";
    secure = true, httpOnly = true,
    maxAge = none(int),
    sameSite = SameSite.Default
  ) =
  ## Add cookie to response but requires the header to be available.
  headers["Set-Cookie"] = cookies.setCookie(
    key, value,
    domain, path, expires,
    true, secure, httpOnly,
    maxAge, sameSite
  )

template setCookie*(
    key, value: string,
    expires: DateTime | Time,
    domain = "", path = "",
    secure = true, httpOnly = true,
    maxAge = none(int),
    sameSite = SameSite.Default
  ) =
  ## Add cookie to response but requires the header to be available.
  ## Expires is set to a DateTime or Time.
  headers["Set-Cookie"] = cookies.setCookie(
    key, value,
    expires,
    domain, path,
    true,
    secure, httpOnly,
    maxAge, sameSite
  )


#
# Param access
#
template params*(request: Request): StringTableRef =
  paramGenerator(request)


template params*(request: Request, s: string): string =
  ## Get params of request.
  paramGeneratorValue(request, s)


template `@`*(s: string): untyped =
  ## Get param.
  paramGeneratorValue(request, s)





#
# General response
#
template resp*(
    httpStatus: HttpCode = Http200,
    headers: HttpHeaders,
    body: string
  ) =
  when defined(dev):
    if headers["Content-Type"] == "":
      echo "Warning: No Content-Type set in response, defaulting to " & $ContentType.Html

  request.respond(httpStatus.ord, headers, body)
  return


template resp*(
    body: string,
    contentType = $ContentType.Html
  ) =
  ## Returns with text/html as default.
  when declared(headers):
    setHeader("Content-Type", $contentType)
    request.respond(200, headers, body)
  else:
    request.respond(200, @[("Content-Type", contentType)], body)
  return


template resp*(
    httpStatus: HttpCode,
  ) =
  ## Returns response code with empty headers and body.
  request.respond(httpStatus.ord, emptyHttpHeaders(), "")
  return


template resp*(
    httpStatus: HttpCode,
    body: string
  ) =
  when declared(headers):
    if not headers.contains("Content-Type"):
      setHeader("Content-Type", $ContentType.Html)
    request.respond(httpStatus.ord, headers, body)
  else:
    request.respond(httpStatus.ord, @[("Content-Type", $ContentType.Html)], body)
  return


template resp*(
    httpStatus: HttpCode,
    contentType: ContentType,
    body: string
  ) =
  when declared(headers):
    setHeader("Content-Type", $contentType)
    request.respond(httpStatus.ord, headers, body)
  else:
    request.respond(httpStatus.ord, @[("Content-Type", $contentType)], body)
  return



#
# Json response
#
template resp*(body: JsonNode) =
  when declared(headers):
    setHeader("Content-Type", $ContentType.Json)
    request.respond(200, headers, $body)
  else:
    request.respond(200, @[("Content-Type", $ContentType.Json)], $body)
  return


template resp*(httpStatus: HttpCode, contentType: ContentType, body: JsonNode) =
  request.respond(httpStatus.ord, @[("Content-Type", $contentType)], $body)
  return


template resp*(httpStatus: HttpCode, body: JsonNode) =
  request.respond(httpStatus.ord, @[("Content-Type", $ContentType.Json)], $body)
  return



#
# Send file
#
template sendFile*(path: string) =
  let r = readFile(path)
  when declared(headers):
    setHeader("Content-Type", newMimetypes().getMimetype(path.split(".")[^1]))
    request.respond(200, headers, r)
  else:
    request.respond(200, @[("Content-Type", newMimetypes().getMimetype(path.split(".")[^1]))], r)
  return


#
# Redirects
#
template redirect*(path: string) =
  when declared(headers):
    headers["Location"] = path
    request.respond(303, headers)
  else:
    request.respond(303, @[("Location", path)])
  return

template redirect*(httpStatus: HttpCode, path: string) =
  when declared(headers):
    headers["Location"] = path
    request.respond(httpStatus.ord, headers)
  else:
    request.respond(httpStatus.ord, @[("Location", path)])
  return

template redirect*(httpStatus: HttpCode, headers: HttpHeaders, path: string) =
  headers["Location"] = path
  request.respond(httpStatus.ord, headers)
  return




