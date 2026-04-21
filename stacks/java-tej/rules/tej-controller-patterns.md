# TEJ/RestExpress Controller Patterns

## Basic Structure
```java
@RestRoute(POST, "/users")
public UserResponse createUser(Request request) {
  UserRequest req = gson.fromJson(request.getBody(), UserRequest.class);
  return userService.create(req);
}
```

## Route Decorators
- `@RestRoute(METHOD, "/path/{id}")` — Route definition
- `METHOD` — GET, POST, PUT, DELETE, PATCH
- Path parameters: `{id}` → `request.getHeader("id")`

## Request/Response
- **Request parsing**: Always use Gson in controller
- **Response**: Return POJO or DTO directly (RestExpress serializes)
- Example:
  ```java
  String json = request.getBody();
  UserRequest req = gson.fromJson(json, UserRequest.class);
  return userService.save(req);
  ```

## HTTP Status Codes
- Return status via `response.setStatus(statusCode)`
- Standard: 200 (OK), 201 (Created), 400 (Bad Request), 404 (Not Found)

## Error Handling
- Catch and wrap in ApplicationServiceException
- RestExpress global error handler formats response
- Example:
  ```java
  try {
    return userService.getUser(id);
  } catch (UserNotFoundException e) {
    throw new ApplicationServiceException(404, "NOT_FOUND", e.getMessage());
  }
  ```

## Validation
- Controllers do NOT validate input
- All validation in service layer
- Service throws ApplicationServiceException on invalid input

---
**Last Updated**: 2026-04-10  
**Stack**: Java 17 TEJ/RestExpress
