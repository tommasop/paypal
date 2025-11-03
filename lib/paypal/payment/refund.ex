defmodule Paypal.Payment.Refund do
  @moduledoc """
  Payment refund information. The information retrieved from Paypal about the
  refund.

  ## Fields

    - `id` - The unique ID for the capture.
    - `status` - The status of the capture (e.g. `"COMPLETED"`).
    - `status_details` - The details of the capture status.
    - `invoice_id` - The API caller-provided external invoice number for this order.
    - `custom_id` - The API caller-provided external ID.
    - `payer` - An embedded schema representing the payer.
    - `create_time` - The date and time when the capture was created (ISO 8601 string).
    - `update_time` - The date and time when the capture was last updated (ISO 8601 string).
    - `amount` - An embedded schema representing the monetary amount of the capture.
    - `acquirer_reference_number` - Reference ID issued for the card transaction.
    - `note_to_payer` - The reason for the refund.
    - `seller_protection` - An embedded schema containing details about seller protection.
    - `seller_payable_breakdown` - An embedded schema that details the seller_payable_breakdown.
    - `links` - A list of embedded link objects for further API actions.
  """

  use TypedEctoSchema
  import Ecto.Changeset
  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Link
  alias Paypal.Common.StatusDetails
  alias Paypal.Order.Payer

  @statuses [
    cancelled: "CANCELLED",
    failed: "FAILED",
    pending: "PENDING",
    completed: "COMPLETED"
  ]

  @primary_key false
  typed_embedded_schema do
    field(:id, :string)
    field(:status, Ecto.Enum, values: @statuses, embed_as: :dumped)
    embeds_one(:status_details, StatusDetails)
    field(:invoice_id, :string)
    field(:custom_id, :string)
    field(:create_time, :string)
    field(:update_time, :string)
    field(:acquirer_reference_number, :string)
    field(:note_to_payer, :string)
    # TODO
    field(:seller_protection, :map)

    # TODO: seller_payable_breakdown - complex structure with gross_amount, paypal_fee, platform_fees, net_amount, total_refunded_amount
    field(:seller_payable_breakdown, :map)

    embeds_one(:payer, Payer)
    embeds_one(:amount, CurrencyValue)
    embeds_many(:links, Link)
  end

  @fields ~w[
     status
     id
     invoice_id
     custom_id
     acquirer_reference_number
     seller_protection
     note_to_payer
     seller_payable_breakdown
     create_time
     update_time
   ]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> cast_embed(:amount, required: true)
    |> cast_embed(:links)
    |> cast_embed(:payer)
    |> cast_embed(:status_details)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
