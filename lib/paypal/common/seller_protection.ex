defmodule Paypal.Common.SellerProtection do
  @moduledoc """
  Seller protection information for payments, authorizations, captures, and refunds.
  """
  use TypedEctoSchema

  @statuses [
    eligible: "ELIGIBLE",
    partially_eligible: "PARTIALLY_ELIGIBLE",
    not_eligible: "NOT_ELIGIBLE"
  ]

  @primary_key false

  typed_embedded_schema do
    field(:status, Ecto.Enum, values: @statuses)
    field(:dispute_categories, {:array, :string})
  end
end
