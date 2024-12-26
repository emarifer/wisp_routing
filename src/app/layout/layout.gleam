import gleam/string_tree

pub fn generate_layout(main_content: String) -> string_tree.StringTree {
  string_tree.from_string("<!DOCTYPE html>
    <html lang='en'>

    <head>
      <meta charset='UTF-8'>
      <meta name='viewport' content='width=device-width, initial-scale=1.0'>
      <meta name='google' content='notranslate' />
      <link rel='shortcut icon' href='/static/lucy.svg' type='image/svg+xml'>
      <title>Wisp Example</title>
      <link rel='stylesheet' href='/static/styles.css'>
    </head>

    <body>
      <main class='pt-24 text-center'>" <> main_content <> "</main>
    </body>

    </html>")
}
