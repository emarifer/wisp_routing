import app/web.{type Context}
import app/web/books
import wisp.{type Request, type Response}

/// The HTTP request handler
///
pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)

  // Wisp no tiene una abstracción de enrutador especial,
  // en su lugar recomendamos usar la antigua búsqueda de patrones habitual.
  // Esto es más rápido que un enrutador, es seguro en cuanto a tipos
  // y significa que no tienes que aprender ni estar limitado
  // por un DSL especial.
  // 
  case wisp.path_segments(req) {
    // Coincide con `/`.
    [] -> books.home_page(req)

    // Coincide con `/show_form`.
    ["show_form"] -> books.show_form(req)

    // Coincide con `/books`.
    ["books"] -> books.all(req, ctx)

    // Coincide con `/books/:id`.
    // El segmento `id` está vinculado a una variable y se pasa al controlador.
    ["books", id] -> books.one(req, id, ctx)

    // Coincide con todas las demás rutas.
    _ -> wisp.not_found()
  }
}
