# mummy_utils
Unofficial utility package for mummy thread server


```nim
import mummy, mommy/routes
import mummy_utils


proc indexCustom(request: Request, details: Details) =
  # Name route param
  echo "projectID:  " & @"projectID"

  # URI query param
  echo "invoiceID:  " & @"invoiceID"

  resp(Http200, "Hello, World!")

var router: Router
router.routerSet(Get, "/project/@projectID/info", indexCustom)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))

```


# Code details



## ContentType*


```nim
  ContentType* = enum
    Json = "application/json"
    Text = "text/plain"
    Html = "text/html; charset=utf-8"
```


## paramGeneratorValue*

```nim
proc paramGeneratorValue*(request: Request, backendRoute: string, s: string): string =
  ## Backend route can contain @named_parameters.
```

Find and return single param from request.

Param priority:
1. URL path
2. URL query
3. body data.



## paramGenerator*

```nim
proc paramGenerator*(request: Request, details: Details): StringTableRef =
```

Generate params from request and returns a table.

Param priority:
1. URL path
2. URL query
3. body data


____

## Request fields

**Examples**

```nim
Request* = object
  params*: StringTableRef       ## Parameters from the pattern, but also the
                                ## query string.
  body*: string                 ## Body of the request, only for POST.
  headers*: HttpHeaders         ## Headers received with the request.
                                ## Retrieving these is case insensitive.
  multipart*: seq[MultipartEntry] ## Form data; only present for
                                ## multipart/form-data
  host*: string                 ## Hostname.
  secure*: bool                 ## From X-Forwarded-Proto header.
  path*: string                 ## Path of request.
  query*: string                ## Query string of request.
  cookies*: StringTableRef      ## Cookies from the browser.
  ip*: string                   ## IP address of the requesting client.
  reqMeth*: HttpMethod          ## Request method, eg. HttpGet, HttpPost

echo request.body
echo request.headers["Content-Type"]
echo request.host
echo request.ip
echo request.path
echo request.query
echo request.reqMethod
echo request.secure
echo request.cookies("glid")
echo request.cookies.hasKey("glid")
```


## Request fields


```nim
proc body*(request: Request): string =
```



```nim
proc host*(request: Request): string =
```



```nim
proc ip*(request: Request): string =
```



```nim
proc path*(request: Request): string =
```



```nim
proc query*(request: Request): string =
```



```nim
proc reqMethod*(request: Request): HttpMethod =
```




```nim
proc multipart*(request: Request): seq[MultipartEntry] =
```




```nim
proc secure*(request: Request): bool =
```




# Headers

**Examples**

```nim
echo request.headers["Content-Type"]
echo request.headers["Content-Typexxx"] # returns empty string
setHeader("Content-Type", "text/plain")
```

## Headers

```nim
proc hasKey*(headers: HttpHeaders, key: string): bool =
```

```nim
template setHeader*(field, value: string) =
```

Set header of response. Requires you to initialize the header first.



# Cookies

**Examples**

```nim
echo request.cookies("glid")
echo request.cookies.hasKey("glid")
let c = request.cookies
echo c["glid"]
```

## cookies*



```nim
proc cookies*(request: Request, cookie: string): string =
```

```nim
proc cookies*(request: Request): StringTableRef =
```

Get cookies of request.


## addCookie*

```nim
template addCookie*(
    key, value: string,
    domain = "", path = "", expires = "";
    noName = false, secure = true, httpOnly = true,
    maxAge = none(int),
    sameSite = SameSite.Default
  ) =
```

Add cookie to response but requires the header to be available.


## addCookie*

```nim
template addCookie*(
    key, value: string,
    expires: DateTime | Time,
    domain = "", path = "",
    noName = false, secure = true, httpOnly = true,
    maxAge = none(int),
    sameSite = SameSite.Default
  ) =
```

Add cookie to response but requires the header to be available.


# Params

**Examples**

```nim
echo request.params("projectID")
echo request.params("invoiceID")

let p = request.params
echo p["projectID"]
echo p.hasKey("invoiceID")
```

## params*


```nim
template params*(request: Request, s: string): string =
```

```nim
template params*(request: Request): StringTableRef =
```

Get params. Is initialized on each call.  Includes named route parameters. Returns the value on first
match in this order:
1. URI path
2. URI query
2. body data

`URI path` names parameters are only available in main route `Details` callback
is available.


## `@`*

```nim
echo @"projectID"
echo @"invoiceID"
```

```nim
template `@`*(s: string): untyped =
```

Get param. Includes named route parameters. Returns the value on first
match in this order:
1. URI path
2. URI query
2. body data

`URI path` names parameters are only available in main route `Details` callback
is available.


# Routes

## routerSet*

```nim
template routerSet*( ) =
## router.routerSet(Get, "/project/@projectID/info", indexCustom)
## router.routerSet(Post, "/project/@projectID/info", indexCustom)
```

Transform router with route and handler. Saving the original route and including the `Details` in in the callback.



# Responses

**Examples**

```nim
resp("Hello, World!")
resp(Http200, "Hello, World!")
resp(Http200, ContentType.Html, "Hello, World!")
resp(Http200, @{"Content-Type": "text/plain"}, "Hello, World!")
```
```nim
resp(%* {"message": "Hello, World!"})
resp(Http200, %* {"message": "Hello, World!"})
resp(Http200, ContentType.Json, %* {"message": "Hello, World!"})
```
```nim
redirect("/project/123/info")
redirect(Http301, "/project/123/info")
```


## resp*() - string



```nim
template resp*(body: string) =
```

```nim
template resp*(httpStatus: HttpCode) =
```


```nim
template resp*(httpStatus: HttpCode, body: string) =
```



```nim
template resp*(httpStatus: HttpCode, contentType: ContentType, body: string) =
```



```nim
template resp*(httpStatus: HttpCode = Http200, headers: HttpHeaders, body: string) =
```


## resp*() - JsonNode

```nim
template resp*(body: JsonNode) =
```


```nim
template resp*(httpStatus: HttpCode, body: JsonNode) =
```


```nim
template resp*(httpStatus: HttpCode, contentType: ContentType, body: JsonNode) =
```



## redirect*


```nim
template redirect*(path: string) =
```


```nim
template redirect*(httpStatus: HttpCode, path: string) =
```


