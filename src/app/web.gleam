import utilities/tiny_database
import wisp

// El tipo `Contexto`, contiene cualquier dato adicional que los
// controladores de solicitudes necesiten, además de la solicitud.
//
// Aquí contiene una conexión de base de datos y la ruta del directorio
// `static`, pero podría contener cualquier otra cosa como claves de API,
// funciones de ejecución de E/S (para que puedan intercambiarse en
// pruebas para implementaciones simuladas), configuración, etc.
//
pub type Context {
  Context(db: tiny_database.Connection, static_directory: String)
}

/// The middleware stack that the request handler uses. The stack is itself a
/// middleware function!
///
/// Middleware wrap each other, so the request travels through the stack from
/// top to bottom until it reaches the request handler, at which point the
/// response travels back up through the stack.
/// 
/// The middleware used here are the ones that are suitable for use in your
/// typical web application.
/// 
pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)

  use <- wisp.log_request(req)
  // https://tour.gleam.run/advanced-features/use/

  use <- wisp.rescue_crashes

  use req <- wisp.handle_head(req)

  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}
