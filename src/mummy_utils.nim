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
export httpcore

# Import query decoder, and `[]` for HttpHeaders
from webby import decodeQueryComponent, `[]`
export `[]`

# !! Missing options isSome and get for multipart

type
  Details* = ref object
    urlOrg*: string
    urlHasParams*: bool

  CallbackHandler* = proc(request: Request, details: Details) {.gcsafe.}

  ContentType* = enum
    Json = "application/json"
    Text = "text/plain"
    Html = "text/html; charset=utf-8"


#
# Param generator
#
proc paramGeneratorValue*(request: Request, backendRoute: string, s: string): string =
  ## Find and return single param from request.
  ##
  ## Starts in:
  ## - URL path
  ## - URL query
  ## - body data.

  let uriSplit  = request.uri.split("?")

  # Path data: /project/@projectID/user/@fileID
  if "@" in backendRoute:
    let
      urlOrg  = backendRoute.split("/")
      uriMain = uriSplit[0].split("/")
    for i in 1..urlOrg.high:
      if urlOrg[i][0] == '@' and urlOrg[i].len() > 1:
        if urlOrg[i][1..^1] == s:
          return uriMain[i]


  # URL query: ?name=thomas
  if uriSplit.len() > 1:
    for pairStr in uriSplit[1].split("#")[0].split('&'):
      let
        pair = pairStr.split('=', 1)
        kv =
          if pair.len == 2:
            (decodeQueryComponent(pair[0]), decodeQueryComponent(pair[1]))
          else:
            (decodeQueryComponent(pair[0]), "")

      if kv[0] == s:
        return kv[1]


  # Body data: name=thomas
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



proc paramGenerator*(request: Request, details: Details): StringTableRef =
  ## Generate params from request.
  ##
  ## Generates all params available in the request.
  ## Starts in:
  ## - URI query
  ## - body data
  ## - URI path

  result = newStringTable()

  let uriSplit  = request.uri.split("?")

  # URL query: ?name=thomas
  if uriSplit.len() > 1:
    for pairStr in uriSplit[1].split("#")[0].split('&'):
      let
        pair = pairStr.split('=', 1)
        kv =
          if pair.len == 2:
            (decodeQueryComponent(pair[0]), decodeQueryComponent(pair[1]))
          else:
            (decodeQueryComponent(pair[0]), "")

      result[kv[0]] = kv[1]


  # Body data: name=thomas
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


  # Path data: /project/@projectID/user/@fileID
  if details != nil and details.urlHasParams:
    let
      urlOrg  = details.urlOrg.split("/")
      uriMain = uriSplit[0].split("/")
    for i in 1..urlOrg.high:
      if urlOrg[i][0] == '@' and urlOrg[i].len() > 1:
        result[urlOrg[i][1..^1]] = uriMain[i]


  return result



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
template params*(request: Request, s: string): string =
  ## Get params of request.
  let d = paramGenerator(request, details)
  d.getOrDefault(s, "")


template params*(request: Request): StringTableRef =
  ## Get params of request. If this is used at a location without the
  ## `Details` object, then the named params will not be available.
  when declared(details):
    paramGenerator(request, details)
  else:
    paramGenerator(request, nil)


template `@`*(s: string): untyped =
  ## Get param.
  paramGeneratorValue(request, details.urlOrg, s)



#
# Callback for routes
#
proc paramCallback(wrapped: CallbackHandler, details: Details): RequestHandler =
  ## Callback where the `Details` is being generated and params
  ## are being made ready.
  return proc(request: Request) =
    wrapped(request, details)



#
# Router transformer
#
template routeSet*(
    router: Router,
    routeType: HttpMethod,
    route: string,
    handler: CallbackHandler
  ) =
  ## Transform router with route and handler.
  ## Saving the original route and including the `Details` in
  ## in the callback.

  # Saving original route
  var
    rFinal: seq[string]
    urlParams: bool = false
  for r in route.split("#")[0].split("/"):
    if r.len() == 0:
      continue
    # Got @-path, replace with *
    elif r[0] == '@':
      rFinal.add("*")
      urlParams = true
    else:
      rFinal.add(r)

  # Generating routes
  case routeType
  of HttpGet:
    router.get(
      "/" & rFinal.join("/"),
      handler.paramCallback(Details(
        urlOrg: route,
        urlHasParams: urlParams,
      ))
    )
  of HttpDelete:
    router.delete(
      "/" & rFinal.join("/"),
      handler.paramCallback(Details(
        urlOrg: route,
        urlHasParams: urlParams,
      ))
    )
  of HttpHead:
    router.head(
      "/" & rFinal.join("/"),
      handler.paramCallback(Details(
        urlOrg: route,
        urlHasParams: urlParams,
      ))
    )
  of HttpPost:
    router.post(
      "/" & rFinal.join("/"),
      handler.paramCallback(Details(
        urlOrg: route,
        urlHasParams: urlParams,
      ))
    )
  of HttpPut:
    router.put(
      "/" & rFinal.join("/"),
      handler.paramCallback(Details(
        urlOrg: route,
        urlHasParams: urlParams,
      ))
    )
  of HttpOptions:
    router.options(
      "/" & rFinal.join("/"),
      handler.paramCallback(Details(
        urlOrg: route,
        urlHasParams: urlParams,
      ))
    )
  of HttpPatch:
    router.patch(
      "/" & rFinal.join("/"),
      handler.paramCallback(Details(
        urlOrg: route,
        urlHasParams: urlParams,
      ))
    )
  else:
    quit("Unknown route type: " & $routeType)



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




