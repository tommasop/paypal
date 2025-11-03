defmodule Paypal.Common.Address do
  @moduledoc """
  Address information for payers, shipping, etc.
  """
  use TypedEctoSchema

  @primary_key false

  typed_embedded_schema do
    field(:address_line_1, :string)
    field(:address_line_2, :string)
    # City
    field(:admin_area_2, :string)
    # State/Province
    field(:admin_area_1, :string)
    field(:postal_code, :string)
    field(:country_code, :string)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  @doc false
  def changeset(struct, params) do
    struct
    |> Ecto.Changeset.cast(params, [
      :address_line_1,
      :address_line_2,
      :admin_area_1,
      :admin_area_2,
      :postal_code,
      :country_code
    ])
  end
end
