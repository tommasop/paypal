defmodule Paypal.Order.Authorization do
  @moduledoc """
  Authorization is the information embebed into the
  `Paypal.Order.Authorized` for getting all of the information for the
  authorized payment.
  """
  use TypedEctoSchema

  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Link
  alias Paypal.Common.StatusDetails
  alias Paypal.Common.SellerProtection

  @statuses [
    created: "CREATED",
    captured: "CAPTURED",
    denied: "DENIED",
    partially_captured: "PARTIALLY_CAPTURED",
    voided: "VOIDED",
    pending: "PENDING",
    completed: "COMPLETED"
  ]

  @primary_key false

  @typedoc """
  The information about the authorization performed on an order.
  The important information here is the `id` because it will be
  important to perform actions using `Paypal.Payment` functions.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:status, Ecto.Enum, values: @statuses, embed_as: :dumped)
    embeds_one(:status_details, StatusDetails)
    field(:invoice_id, :string)
    field(:custom_id, :string)
    embeds_one(:amount, CurrencyValue)
    # TODO
    field(:network_transaction_reference, :map)

    embeds_one(:seller_protection, SellerProtection)

    field(:expiration_time, :utc_datetime)
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
    embeds_many(:links, Link)
  end
end
