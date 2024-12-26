import app/router
import app/web
import gleam/erlang/process
import mist
import utilities/tiny_database
import wisp
import wisp/wisp_mist

const custom_port = 8000

const data_directory = "tmp/data"

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)

  // Aquí se crea una base de datos cuando se inicia el programa.
  // Esta conexión la utilizan todas las solicitudes.
  use db <- tiny_database.with_connection(data_directory)

  // Se construye un contexto para contener la conexión a la base de datos.
  let context = web.Context(db, static_directory())

  // La función handle_request se aplica parcialmente con el contexto para crear
  // la función del controlador de solicitudes que solo acepta solicitudes.
  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    handler
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(custom_port)
    |> mist.start_http

  process.sleep_forever()
}

pub fn static_directory() -> String {
  // El directorio privado es donde almacenamos archivos
  // que no son de Gleam ni de Erlang,
  // incluidos los recursos estáticos que se entregarán.
  // Esta función devuelve una ruta absoluta
  // y funciona tanto en desarrollo como en
  // producción después de la compilación.
  let assert Ok(priv_directory) = wisp.priv_directory("wisp_routing")

  priv_directory <> "/static"
}
// curl -v http://localhost:8000 | json_p
// curl -v -X DELETE http://localhost:8000 | json_p
