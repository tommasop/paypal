defmodule Paypal.Common.Name do
  @moduledoc """
  Name information for payers and other entities.
  """
  use TypedEctoSchema

  @primary_key false

  typed_embedded_schema do
    field(:given_name, :string)
    field(:surname, :string)
    field(:full_name, :string)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  @doc false
  def changeset(struct, params) do
    struct
    |> Ecto.Changeset.cast(params, [:given_name, :surname, :full_name])
  end
end
