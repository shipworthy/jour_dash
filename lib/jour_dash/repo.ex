defmodule JourDash.Repo do
  use Ecto.Repo,
    otp_app: :jour_dash,
    adapter: Ecto.Adapters.Postgres
end
