use Mix.Config

config :lager,
  error_logger_redirect: true,
  colored: true,
  handlers: [
    lager_console_backend: [level: :notice]
  ]

config :logger,
  level: :error,
  truncate: 4096
