defmodule Electrofrenetic.Repo do
  use Ecto.Repo,
    otp_app: :electrofrenetic,
    adapter: Ecto.Adapters.Postgres
end
