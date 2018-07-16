use Mix.Config

config :lager,
  error_logger_redirect: true,
  colored: true,
  handlers: [
    lager_console_backend: [
      level: :notice,
      formatter: :lager_default_formatter,
      formatter_config: [:time, :color, " [", :severity, "] <", :pid, "> ", :message, "\e[0m\r\n"]
    ]
  ]

config :logger,
  level: :error,
  truncate: 4096
