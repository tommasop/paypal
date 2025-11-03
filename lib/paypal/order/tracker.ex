defmodule Paypal.Order.Tracker do
  @moduledoc """
  Represents tracking information for an order shipment.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:transaction_id, :string)
    field(:tracking_number, :string)
    field(:carrier, :string)
    field(:capture_id, :string)
    field(:notify_payer, :boolean, default: false)
    field(:items, {:array, :map}, default: [])
  end

  @doc """
  Creates a changeset for validating tracker data.
  """
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :transaction_id,
      :tracking_number,
      :carrier,
      :capture_id,
      :notify_payer,
      :items
    ])
    |> validate_required([:transaction_id, :tracking_number, :carrier])
    |> validate_length(:tracking_number, min: 1, max: 64)
    |> validate_inclusion(:carrier, ["UPS", "USPS", "FEDEX", "DHL", "OTHER"])
  end
end
