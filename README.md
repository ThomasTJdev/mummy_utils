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
```

Find and return single param from request. 

 Starts in: - URL path - URL query - body data.



## paramGenerator*

```nim
proc paramGenerator*(request: Request, details: Details): StringTableRef =
```

Generate params from request. 

 Generates all params available in the request. Starts in: - URI query - body data - URI path


____

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



```nim
proc hasKey*(headers: HttpHeaders, key: string): bool =
```


```nim
template setHeader*(field, value: string) =
```

Set header of response. Requires you to initialize the header first.



# Cookies

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

## params*

```nim
template params*(request: Request, s: string): string =
```



```nim
template params*(request: Request): StringTableRef =
```




## `@`*

```nim
template `@`*(s: string): untyped =
```

Get param. Includes named route parameters.



# Routes

## routerSet*

```nim
template routerSet*( ) =
## router.routerSet(Get, "/project/@projectID/info", indexCustom)
## router.routerSet(Post, "/project/@projectID/info", indexCustom)
```

Transform router with route and handler. Saving the original route and including the `Details` in in the callback.



# Responses

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


